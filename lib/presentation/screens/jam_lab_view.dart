import 'dart:async';
import 'dart:io';
import 'dart:ui' show FontFeature;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/jam_probe.dart';
import '../../core/services/jam_state.dart';
import '../common/aether_title_bar.dart';
import '../state/cloud_sync_provider.dart';
import '../theme/aether_colors.dart';

/// Developer test screen for the planned "Jam" (listen together) feature. Open it with
/// 5 quick taps on the Version row in Settings.
///
/// It runs the REAL sync approach with a pretend player (no audio):
///  * Every device writes its state into ITS OWN Drive file, and only when something happens
///    (play, pause, seek, next song) plus a slow heartbeat.
///  * Every device polls the friend's file (cheap version check, download only on change).
///  * The live position is computed from "position at time written" + elapsed time.
/// Run it on two devices at the same time and compare the position shown on both.
/// The "Developer" box has the 2-second stress mode that looks for the limits of Drive.
class JamLabView extends ConsumerStatefulWidget {
  const JamLabView({super.key});

  @override
  ConsumerState<JamLabView> createState() => _JamLabViewState();
}

class _JamLabViewState extends ConsumerState<JamLabView> {
  late final JamProbe _probe;
  late final String _who;

  final TextEditingController _friendIdController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final List<String> _log = <String>[];

  String? _myFileId;
  bool _friendFilePublic = false;

  /// How far THIS device's clock is ahead of Google's (measured when the jam starts).
  Duration _offset = Duration.zero;

  // The pretend player.
  bool _playing = false;
  int _song = 1;
  int _anchorPositionMs = 0;
  DateTime? _anchorAt;

  // Sync engine.
  bool _jamOn = false;
  int _rev = 0;
  DateTime? _lastLocalChangeAt;
  int _pollSeconds = 2;
  bool _stress = false;
  Timer? _pollTimer;
  Timer? _heartbeatTimer;
  Timer? _uiTimer;
  bool _writeBusy = false;
  bool _writeAgain = false;
  bool _readBusy = false;
  String? _lastVersion;
  DateTime? _lastRemoteWrittenAt;
  final DelayStats _stats = DelayStats();

  @override
  void initState() {
    super.initState();
    final service = ref.read(googleDriveSyncServiceProvider);
    // No e-mail in the label: the log is meant to be copied and shared.
    _who = '${Platform.operatingSystem}-${DateTime.now().millisecondsSinceEpoch % 9000 + 1000}';
    _probe = JamProbe(({bool forceRefresh = false}) => service.driveApiForFeatures(forceRefresh: forceRefresh));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _heartbeatTimer?.cancel();
    _uiTimer?.cancel();
    _friendIdController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ───────────────────────── helpers ─────────────────────────

  void _add(String text) {
    if (!mounted) return;
    final t = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp = '${two(t.hour)}:${two(t.minute)}:${two(t.second)}.${t.millisecond.toString().padLeft(3, '0')}';
    setState(() {
      _log.insert(0, '$stamp  $text');
      if (_log.length > 300) _log.removeLast();
    });
  }

  Future<void> _run(String label, Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      _add('$label FAILED: ${JamProbe.describe(e)}');
    }
  }

  /// Google's time as this device estimates it.
  DateTime _googleNow() => DateTime.now().toUtc().subtract(_offset);

  int _livePosition(DateTime googleNow) {
    final anchor = _anchorAt;
    if (!_playing || anchor == null) return _anchorPositionMs;
    final elapsed = googleNow.difference(anchor).inMilliseconds;
    return _anchorPositionMs + (elapsed > 0 ? elapsed : 0);
  }

  static String _clock(int ms) {
    final total = ms ~/ 1000;
    final minutes = (total ~/ 60).toString().padLeft(2, '0');
    final seconds = (total % 60).toString().padLeft(2, '0');
    final tenths = ((ms % 1000) ~/ 100).toString();
    return '$minutes:$seconds.$tenths';
  }

  static String _delayText(Duration d) => '${(d.inMilliseconds / 1000).toStringAsFixed(1)} s';

  // ───────────────────────── setup ─────────────────────────

  Future<void> _createFile() async {
    final first = JamState(
      rev: 0,
      songId: 'lab-1',
      title: 'Test song 1',
      playing: false,
      positionMs: 0,
      writtenAt: DateTime.now().toUtc(),
      writer: _who,
    );
    final id = await _probe.createFile(first.encode());
    if (!mounted) return;
    setState(() => _myFileId = id);
    _add('Created my file. ID: $id   (give it to the other device)');
  }

  // ───────────────────────── the jam ─────────────────────────

  Future<void> _startJam() async {
    if (_myFileId == null) {
      _add('Create my file first');
      return;
    }
    if (_friendIdController.text.trim().isEmpty) {
      _add("Paste the other device's file ID first");
      return;
    }
    _offset = await _probe.clockOffsetToGoogle();
    _add('Clock check: this device is ${_offset.inMilliseconds} ms ahead of Google (accuracy about 1 s)');
    _lastVersion = null;
    _lastRemoteWrittenAt = null;
    if (!mounted) return;
    setState(() => _jamOn = true);
    _startTimers();
    _add('JAM ON: poll every $_pollSeconds s, heartbeat every ${_heartbeatSeconds()} s${_stress ? ' (STRESS MODE)' : ''}');
    unawaited(_scheduleWrite());
  }

  void _stopJam() {
    _pollTimer?.cancel();
    _heartbeatTimer?.cancel();
    _uiTimer?.cancel();
    _pollTimer = _heartbeatTimer = _uiTimer = null;
    setState(() => _jamOn = false);
    _add('JAM OFF');
  }

  int _heartbeatSeconds() => _stress ? 2 : 15;

  void _startTimers() {
    _pollTimer?.cancel();
    _heartbeatTimer?.cancel();
    _uiTimer?.cancel();
    _pollTimer = Timer.periodic(Duration(seconds: _pollSeconds), (_) => _pollTick());
    _heartbeatTimer = Timer.periodic(Duration(seconds: _heartbeatSeconds()), (_) {
      // Normal mode: only while playing, so the others can correct small drift.
      // Stress mode: always, to find the limits of Drive.
      if (_playing || _stress) unawaited(_scheduleWrite());
    });
    _uiTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted) setState(() {});
    });
  }

  /// A button of the pretend player. Changes the local state, then tells the friend.
  void _localEvent(String what, void Function(DateTime googleNow) change) {
    if (!_jamOn) {
      _add('Start the jam first');
      return;
    }
    final now = _googleNow();
    change(now);
    _lastLocalChangeAt = now;
    _add('LOCAL: $what');
    setState(() {});
    unawaited(_scheduleWrite());
  }

  void _play() => _localEvent('play', (g) {
        if (_playing) return;
        _anchorPositionMs = _livePosition(g);
        _anchorAt = g;
        _playing = true;
      });

  void _pause() => _localEvent('pause', (g) {
        if (!_playing) return;
        _anchorPositionMs = _livePosition(g);
        _anchorAt = g;
        _playing = false;
      });

  void _seek(int deltaMs) => _localEvent('seek ${deltaMs > 0 ? '+' : ''}${deltaMs ~/ 1000} s', (g) {
        final target = _livePosition(g) + deltaMs;
        _anchorPositionMs = target < 0 ? 0 : target;
        _anchorAt = g;
      });

  void _nextSong() => _localEvent('next song', (g) {
        _song++;
        _anchorPositionMs = 0;
        _anchorAt = g;
        _playing = true;
      });

  /// Writes my state to my own file. Many events in a row are merged into one write.
  Future<void> _scheduleWrite() async {
    final id = _myFileId;
    if (id == null) return;
    if (_writeBusy) {
      _writeAgain = true;
      return;
    }
    _writeBusy = true;
    try {
      do {
        _writeAgain = false;
        final now = _googleNow();
        final state = JamState(
          rev: ++_rev,
          songId: 'lab-$_song',
          title: 'Test song $_song',
          playing: _playing,
          positionMs: _livePosition(now),
          writtenAt: now,
          writer: _who,
        );
        final started = DateTime.now();
        await _probe.writeText(id, state.encode());
        _add('WRITE rev ${state.rev} (${state.playing ? 'playing' : 'paused'} at ${_clock(state.positionMs)}) '
            'took ${DateTime.now().difference(started).inMilliseconds} ms');
      } while (_writeAgain);
    } catch (e) {
      _add('WRITE FAILED: ${JamProbe.describe(e)}');
    } finally {
      _writeBusy = false;
    }
  }

  /// Looks at the friend's file. Cheap version check first; downloads only when it changed.
  Future<void> _pollTick() async {
    final friendId = _friendIdController.text.trim();
    if (friendId.isEmpty || _readBusy) return;
    _readBusy = true;
    try {
      String content;
      String? version;
      if (_friendFilePublic) {
        content = await _probe.readPublic(friendId);
      } else {
        final meta = await _probe.readMeta(friendId);
        version = meta.version;
        if (version == _lastVersion) return; // nothing new: no download
        content = await _probe.readContent(friendId);
      }
      final seenAt = _googleNow();
      final remote = JamState.tryParse(content);
      if (remote == null) {
        _add('READ ok, but the content is not a jam state');
        return;
      }
      if (_friendFilePublic && remote.writtenAt == _lastRemoteWrittenAt) return;
      _lastVersion = version;
      _lastRemoteWrittenAt = remote.writtenAt;

      final delay = seenAt.difference(remote.writtenAt);
      _stats.add(delay);

      final decision = JamState.decide(
        remote: remote,
        myWriter: _who,
        lastLocalChangeAt: _lastLocalChangeAt,
        localSongId: 'lab-$_song',
        localPlaying: _playing,
        localPositionMs: _livePosition(seenAt),
        now: seenAt,
      );
      final remoteText = '${remote.playing ? 'playing' : 'paused'} ${remote.title} at ${_clock(remote.livePositionMs(seenAt))}';
      if (decision == JamDecision.apply) {
        _song = int.tryParse(remote.songId.replaceFirst('lab-', '')) ?? _song;
        _playing = remote.playing;
        _anchorPositionMs = remote.livePositionMs(seenAt);
        _anchorAt = seenAt;
        _add('REMOTE rev ${remote.rev} APPLIED: $remoteText   (seen ${_delayText(delay)} after written)');
      } else {
        _add('REMOTE rev ${remote.rev} ignored (in sync, or older than my last action): $remoteText   '
            '(seen ${_delayText(delay)} after written)');
      }
    } catch (e) {
      _add('READ FAILED: ${JamProbe.describe(e)}');
    } finally {
      _readBusy = false;
      if (mounted) setState(() {});
    }
  }

  // ───────────────────────── UI ─────────────────────────

  Widget _section(String title, String help, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AetherColors.ultraDarkGray,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(help, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _button(String label, VoidCallback? onPressed) => OutlinedButton(
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontSize: 12)),
      );

  @override
  Widget build(BuildContext context) {
    final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    final bottom = MediaQuery.of(context).padding.bottom + 24;
    final id = _myFileId;
    final position = _livePosition(_googleNow());

    return Container(
      color: AetherColors.deepMatteBlack,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: isDesktop ? 40 : 0),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text('JAM LAB (TEST)', style: TextStyle(fontSize: 12, letterSpacing: 3, color: Colors.white)),
              ),
              body: ListView(
                padding: EdgeInsets.fromLTRB(16, 8, 16, bottom),
                children: [
                  Text('This device: $_who', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 12),
                  _section(
                    '1. SETUP (do this on BOTH devices)',
                    'Each device has its own file. Give your file ID to the other device and share the file with its Google e-mail.',
                    [
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _button('Create my file', () => _run('Create', _createFile)),
                        _button('Copy my file ID', id == null ? null : () => Clipboard.setData(ClipboardData(text: id))),
                      ]),
                      if (id != null) SelectableText('My file ID: $id', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: "Other device's Google e-mail", isDense: true),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _button('Share my file with that e-mail', id == null ? null : () => _run('Share', () async {
                              final email = _emailController.text.trim();
                              if (email.isEmpty) {
                                _add("Type the other device's e-mail first");
                                return;
                              }
                              await _probe.share(id, email, canEdit: false);
                              _add('Shared my file with the e-mail you typed (read only)');
                            })),
                        _button('Or: make my file public', id == null ? null : () => _run('Public', () async {
                              await _probe.makePublic(id);
                              _add('Anyone with my file ID can read it now');
                            })),
                      ]),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _friendIdController,
                        decoration: const InputDecoration(labelText: "Other device's file ID", isDense: true),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      SwitchListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Other file is public: read it without login", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        value: _friendFilePublic,
                        onChanged: (v) => setState(() {
                          _friendFilePublic = v;
                          _lastVersion = null;
                          _lastRemoteWrittenAt = null;
                        }),
                      ),
                    ],
                  ),
                  _section(
                    '2. MINI JAM (pretend player, no sound)',
                    'Start it on both devices. Press the buttons on either one and compare the position on both screens.',
                    [
                      Row(children: [
                        Switch(value: _jamOn, onChanged: (on) => on ? _run('Start', _startJam) : _stopJam()),
                        const Text('Jam on', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(width: 16),
                        const Text('poll', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(width: 6),
                        DropdownButton<int>(
                          value: _pollSeconds,
                          dropdownColor: AetherColors.ultraDarkGray,
                          items: const [2, 5, 10].map((s) => DropdownMenuItem<int>(value: s, child: Text('every $s s'))).toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _pollSeconds = v);
                            if (_jamOn) _startTimers();
                          },
                        ),
                      ]),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
                        child: Column(children: [
                          Text('Test song $_song', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(_clock(position),
                              style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold, fontFeatures: [FontFeature.tabularFigures()])),
                          Text(_playing ? 'PLAYING' : 'PAUSED',
                              style: TextStyle(color: _playing ? AetherColors.success : Colors.white54, fontSize: 12, letterSpacing: 2)),
                        ]),
                      ),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _button('Play', _play),
                        _button('Pause', _pause),
                        _button('-30 s', () => _seek(-30000)),
                        _button('+30 s', () => _seek(30000)),
                        _button('Next song', _nextSong),
                      ]),
                      const SizedBox(height: 10),
                      Text('Delay (written to seen): ${_stats.summary}',
                          style: const TextStyle(color: AetherColors.accentAmber, fontSize: 12)),
                      Text('Drive requests: ${_probe.requests}   errors: ${_probe.failures}',
                          style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text('DEVELOPER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: const Text('Stress test and single actions', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      children: [
                        SwitchListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('STRESS MODE: write every 2 s, even when paused',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                          subtitle: const Text('Looks for the limits of Drive. Watch the error counter and the log.',
                              style: TextStyle(color: Colors.white38, fontSize: 11)),
                          value: _stress,
                          onChanged: (v) {
                            setState(() => _stress = v);
                            if (_jamOn) {
                              _startTimers();
                              _add('Stress mode ${v ? 'ON: heartbeat every 2 s' : 'OFF: heartbeat every 15 s'}');
                            }
                          },
                        ),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          _button('Read other file once (login)', () => _run('Read', () async {
                                final text = await _probe.readContent(_friendIdController.text.trim());
                                _add('READ LOGIN ok: $text');
                              })),
                          _button('Read other file once (public)', () => _run('Read public', () async {
                                final text = await _probe.readPublic(_friendIdController.text.trim());
                                _add('READ PUBLIC ok: $text');
                              })),
                          _button('List files shared with me', () => _run('List', () async {
                                final files = await _probe.listSharedWithMe();
                                _add(files.isEmpty ? 'Shared-with-me list is EMPTY' : 'Shared with me: ${files.join(' | ')}');
                              })),
                          _button('Delete my file', id == null ? null : () => _run('Delete', () async {
                                await _probe.deleteFile(id);
                                if (!mounted) return;
                                setState(() => _myFileId = null);
                                _add('Deleted my file');
                              })),
                        ]),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  _section(
                    'LOG',
                    'Newest first. Copy it and send it back.',
                    [
                      Wrap(spacing: 8, children: [
                        _button('Copy log', () => Clipboard.setData(ClipboardData(text: _log.reversed.join('\n')))),
                        _button('Clear', () => setState(_log.clear)),
                      ]),
                      const SizedBox(height: 8),
                      for (final line in _log.take(120))
                        Text(line, style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isDesktop) const AetherTitleBar(),
        ],
      ),
    );
  }
}

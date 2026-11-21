import 'dart:convert';

/// What a jam participant tells the others. Each participant writes this into THEIR OWN
/// Drive file and reads the files of the others (see jam_probe.dart).
///
/// The position is not sent every second. A state says "at [writtenAt] the song was at
/// [positionMs] and [playing]"; everybody computes the live position with [livePositionMs].
class JamState {
  const JamState({
    required this.rev,
    required this.songId,
    required this.title,
    required this.playing,
    required this.positionMs,
    required this.writtenAt,
    required this.writer,
  });

  /// Counts up with every write of this writer.
  final int rev;
  final String songId;
  final String title;
  final bool playing;

  /// Position of the song at [writtenAt].
  final int positionMs;

  /// Google's time (UTC) when this was written, as estimated by the writer's device.
  final DateTime writtenAt;

  /// Who wrote it (device label).
  final String writer;

  /// The position right now, [googleNow] being Google's time.
  int livePositionMs(DateTime googleNow) {
    if (!playing) return positionMs;
    final elapsed = googleNow.difference(writtenAt).inMilliseconds;
    return positionMs + (elapsed > 0 ? elapsed : 0);
  }

  String encode() => jsonEncode(<String, dynamic>{
        'v': 1,
        'rev': rev,
        'songId': songId,
        'title': title,
        'playing': playing,
        'positionMs': positionMs,
        'writtenAtMs': writtenAt.toUtc().millisecondsSinceEpoch,
        'writer': writer,
      });

  /// Null for anything that is not a jam state (never throws).
  static JamState? tryParse(String text) {
    try {
      final data = jsonDecode(text);
      if (data is! Map<String, dynamic>) return null;
      final rev = data['rev'];
      final songId = data['songId'];
      final playing = data['playing'];
      final position = data['positionMs'];
      final writtenAt = data['writtenAtMs'];
      if (rev is! int || songId is! String || playing is! bool || position is! int || writtenAt is! int) {
        return null;
      }
      return JamState(
        rev: rev,
        songId: songId,
        title: data['title'] is String ? data['title'] as String : songId,
        playing: playing,
        positionMs: position < 0 ? 0 : position,
        writtenAt: DateTime.fromMillisecondsSinceEpoch(writtenAt, isUtc: true),
        writer: data['writer'] is String ? data['writer'] as String : '?',
      );
    } catch (_) {
      return null;
    }
  }

  /// Should this device follow the state [remote] of a friend?
  ///
  ///  * Own file: never.
  ///  * Older than my own last action: no. My action wins and my write reaches the friend.
  ///  * Another song, or play/pause changed: yes.
  ///  * Same song and same play state: only when the positions differ by more than
  ///    [driftToleranceMs] (a seek, or real drift). Small differences are left alone so the
  ///    music is not disturbed by every heartbeat. The tolerance is 2.5 s because the devices
  ///    know Google's time only to about +-1 s each; a smaller value would make two devices
  ///    correct each other back and forth.
  ///
  /// When two people act at the same moment, the later [writtenAt] wins on both devices.
  static JamDecision decide({
    required JamState remote,
    required String myWriter,
    required DateTime? lastLocalChangeAt,
    required String localSongId,
    required bool localPlaying,
    required int localPositionMs,
    required DateTime now,
    int driftToleranceMs = 2500,
  }) {
    if (remote.writer == myWriter) return JamDecision.ignore;
    if (lastLocalChangeAt != null && !remote.writtenAt.isAfter(lastLocalChangeAt)) return JamDecision.ignore;
    if (remote.songId != localSongId) return JamDecision.apply;
    if (remote.playing != localPlaying) return JamDecision.apply;
    final difference = (remote.livePositionMs(now) - localPositionMs).abs();
    return difference > driftToleranceMs ? JamDecision.apply : JamDecision.ignore;
  }
}

enum JamDecision { ignore, apply }

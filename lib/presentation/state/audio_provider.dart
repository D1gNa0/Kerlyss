import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'package:kerlyss/core/services/logger_service.dart';
import 'package:kerlyss/core/services/youtube_proxy_server.dart';

import 'audio_state.dart';

final audioProvider = StateNotifierProvider<AudioNotifier, AudioState>((ref) {
  return AudioNotifier();
});

/// Audio engine backed by just_audio.
/// YouTube playback goes through a local proxy so the player only sees a plain
/// HTTP audio stream.
class AudioNotifier extends StateNotifier<AudioState> {
  final AudioPlayer _player = AudioPlayer();

  final _frequencyController = StreamController<List<double>>.broadcast();
  Stream<List<double>> get frequencyStream => _frequencyController.stream;
  Timer? _visualizerTimer;

  final List<StreamSubscription<dynamic>> _subs = [];

  AudioNotifier()
      : super(
          AudioState(
            currentSong: SongMetadata.empty(),
            status: PlaybackStatus.idle,
            position: Duration.zero,
            bufferedPosition: Duration.zero,
          ),
        ) {
    _init();
    _startVibrancyLoop();
  }

  void _init() {
    _subs.add(_player.playerStateStream.listen((playerState) {
      if (!mounted) return;

      final nextStatus = switch (playerState.processingState) {
        ProcessingState.idle => PlaybackStatus.idle,
        ProcessingState.loading => PlaybackStatus.loading,
        ProcessingState.buffering => PlaybackStatus.buffering,
        ProcessingState.ready =>
          playerState.playing ? PlaybackStatus.playing : PlaybackStatus.paused,
        ProcessingState.completed => PlaybackStatus.completed,
      };

      Log.i('just_audio state: playing=${playerState.playing}, processing=${playerState.processingState}');
      state = state.copyWith(status: nextStatus);
    }));

    _subs.add(_player.positionStream.listen((position) {
      if (!mounted) return;
      state = state.copyWith(position: position);
    }));

    _subs.add(_player.bufferedPositionStream.listen((bufferedPosition) {
      if (!mounted) return;
      state = state.copyWith(bufferedPosition: bufferedPosition);
    }));

    _player.setVolume(1.0);
  }

  void _startVibrancyLoop() {
    _visualizerTimer?.cancel();
    _visualizerTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      if (state.status == PlaybackStatus.playing) {
        final bands = List.generate(16, (i) {
          final base = (1.0 - (i / 16.0)) * 0.4;
          return (base + (DateTime.now().millisecond % 1000) / 1000.0 * 0.6)
              .clamp(0.1, 1.0);
        });
        _frequencyController.add(bands);
      } else {
        _frequencyController.add(List.generate(16, (_) => 0.0));
      }
    });
  }

  Future<void> playSong(SongMetadata song, String sourceUrl) async {
    state = state.copyWith(currentSong: song, status: PlaybackStatus.loading);
    Log.i('playSong triggered. Initial sourceUrl: $sourceUrl');

    try {
      if (sourceUrl.startsWith('file://') || File(sourceUrl).existsSync()) {
        final localPath = sourceUrl.startsWith('file://')
            ? Uri.parse(sourceUrl).toFilePath()
            : sourceUrl;

        Log.i('playSong -> Opening local file: $localPath');
        await _player.setFilePath(localPath);
        await _player.play();
        Log.i('playSong -> local file started successfully');
        return;
      }

      String? videoId;
      final uri = Uri.tryParse(sourceUrl);

      if (uri != null &&
          (uri.host.contains('youtube') || uri.host.contains('youtu.be'))) {
        videoId = uri.queryParameters['v'];
        videoId ??= uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
      } else if (!sourceUrl.startsWith('http')) {
        videoId = sourceUrl;
      }

      if (videoId != null && videoId.length != 11) {
        Log.w(
          'VideoId validation warning: extracted "$videoId" '
          '(length=${videoId.length}, expected 11)',
        );
      }

      Log.i('playSong -> Extracted videoId: "$videoId" from sourceUrl: "$sourceUrl"');

      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      };

      if (videoId != null && videoId.isNotEmpty) {
        final port = await YoutubeProxyServer.start();
        final proxyUrl = 'http://127.0.0.1:$port/?id=$videoId';

        Log.i('playSong -> Opening PROXY stream: $proxyUrl');
        await _player.setUrl(proxyUrl, headers: headers);
      } else {
        Log.i('playSong -> Opening direct stream: $sourceUrl');
        await _player.setUrl(sourceUrl, headers: headers);
      }

      await _player.play();
      Log.i('playSong -> just_audio started successfully');
    } catch (e, stacktrace) {
      Log.e('playSong -> FATAL ERROR: $e');
      Log.e('Stacktrace: $stacktrace');
      if (mounted) {
        state = state.copyWith(status: PlaybackStatus.error);
      }
    }
  }

  void togglePlay() {
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void seek(Duration position) {
    _player.seek(position);
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _visualizerTimer?.cancel();
    _frequencyController.close();
    _player.dispose();
    super.dispose();
  }
}

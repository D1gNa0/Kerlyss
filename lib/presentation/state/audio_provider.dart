import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerlyss/core/services/logger_service.dart';
import 'package:kerlyss/core/services/youtube_proxy_server.dart';
import 'package:media_kit/media_kit.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'audio_state.dart';
import '../../core/services/logger_service.dart';

final audioProvider = StateNotifierProvider<AudioNotifier, AudioState>((ref) {
  return AudioNotifier();
});

/// Audio engine backed by media_kit (libmpv).
/// Replaces just_audio_windows which had unfixable threading crashes.
///
/// YouTube resolution strategy:
///   1. Extract video ID from any source URL format
///   2. Use youtube_explode_dart to get the signed CDN URL + provide YouTube headers
///   3. media_kit / libmpv passes headers on every HTTP request (including range requests)
///   → Seeking works natively, no buffer-all-first issue.
class AudioNotifier extends StateNotifier<AudioState> {
  final Player _player = Player(
    configuration: const PlayerConfiguration(
      logLevel: MPVLogLevel.debug,
      title: 'Kerlyss',
    ),
  );
  final YoutubeExplode _yt = YoutubeExplode();

  // Visualizer
  final _frequencyController = StreamController<List<double>>.broadcast();
  Stream<List<double>> get frequencyStream => _frequencyController.stream;
  Timer? _visualizerTimer;

  // Subscriptions
  final List<StreamSubscription> _subs = [];

  AudioNotifier()
      : super(AudioState(
          currentSong: SongMetadata.empty(),
          status: PlaybackStatus.idle,
          position: Duration.zero,
          bufferedPosition: Duration.zero,
        )) {
    _init();
    _startVibrancyLoop();
  }

  void _init() {
    _subs.add(_player.stream.playing.listen((playing) {
      if (!mounted) return;
      Log.i('media_kit playing: $playing');
      state = state.copyWith(
        status: playing ? PlaybackStatus.playing : PlaybackStatus.paused,
      );
    }));

    _subs.add(_player.stream.log.listen((event) {
      Log.i('MPV LOG: [${event.level}] ${event.prefix}: ${event.text}');
    }));

    _subs.add(_player.stream.position.listen((pos) {
      if (!mounted) return;
      state = state.copyWith(position: pos);
    }));
    
    _player.setVolume(100.0);

    _subs.add(_player.stream.buffering.listen((buffering) {
      if (!mounted) return;
      if (buffering && state.status == PlaybackStatus.loading) {
        state = state.copyWith(status: PlaybackStatus.buffering);
      }
    }));

    _subs.add(_player.stream.completed.listen((completed) {
      if (!mounted) return;
      if (completed) {
        state = state.copyWith(status: PlaybackStatus.completed);
      }
    }));

    _subs.add(_player.stream.error.listen((error) {
      if (!mounted) return;
      if (error != null) {
        state = state.copyWith(status: PlaybackStatus.error);
      }
    }));
  }

  void _startVibrancyLoop() {
    _visualizerTimer?.cancel();
    _visualizerTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      if (state.status == PlaybackStatus.playing) {
        final List<double> bands = List.generate(16, (i) {
          final double base = (1.0 - (i / 16.0)) * 0.4;
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
      // 1. Extract YouTube video ID from any format:
      //    - https://www.youtube.com/watch?v=VIDEO_ID
      //    - https://youtu.be/VIDEO_ID
      //    - bare VIDEO_ID string
      String? videoId;
      final uri = Uri.tryParse(sourceUrl);
      if (uri != null &&
          (uri.host.contains('youtube') || uri.host.contains('youtu.be'))) {
        videoId = uri.queryParameters['v'] ?? uri.pathSegments.lastOrNull;
      } else if (!sourceUrl.startsWith('http')) {
        videoId = sourceUrl;
      }

      Log.i('playSong -> Extracted videoId: $videoId');

      String streamUrl;

      if (videoId != null && videoId.isNotEmpty) {
        // 2. Resolve signed CDN URL via youtube_explode_dart
        // Start the proxy server to handle streaming internally and absolutely bypass 403s
        final port = await YoutubeProxyServer.start();
        final proxyUrl = 'http://127.0.0.1:$port/?id=$videoId';

        Log.i('playSong -> Instructing media_kit to open PROXY stream: $proxyUrl');
        
        // Pass standard headers just in case, though the proxy handles the fetch.
        final headers = {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        };

        await _player.open(Media(proxyUrl, httpHeaders: headers));
        Log.i('playSong -> media_kit instructed successfully.');

      } else {
        final streamUrl = sourceUrl;
        Log.i('playSong -> Instructing media_kit to open direct stream...');
        await _player.open(Media(streamUrl));
        Log.i('playSong -> media_kit instructed successfully.');
      }

    } catch (e, stacktrace) {
      Log.e('playSong -> FATAL ERROR during launch: $e');
      Log.e(stacktrace.toString());
      if (mounted) {
        state = state.copyWith(status: PlaybackStatus.error);
      }
    }
  }

  void togglePlay() {
    _player.playOrPause();
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
    _yt.close();
    super.dispose();
  }
}

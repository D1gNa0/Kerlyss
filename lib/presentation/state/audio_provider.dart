import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'audio_state.dart';
import '../../data/repositories/repository_providers.dart';
import '../../data/datasources/remote/youtube_audio_engine.dart';
import '../../data/datasources/remote/youtube_audio_source.dart';

final audioProvider = StateNotifierProvider<AudioNotifier, AudioState>((ref) {
  final ytEngine = ref.watch(youtubeAudioEngineProvider);
  return AudioNotifier(ytEngine);
});

class AudioNotifier extends StateNotifier<AudioState> {
  final AudioPlayer _player = AudioPlayer();
  final YoutubeAudioEngine _ytEngine;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;
  
  // Visualizer Stream
  final _frequencyController = StreamController<List<double>>.broadcast();
  Stream<List<double>> get frequencyStream => _frequencyController.stream;
  Timer? _visualizerTimer;

  AudioNotifier(this._ytEngine)
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
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      PlaybackStatus status;
      if (state.processingState == ProcessingState.loading) {
        status = PlaybackStatus.loading;
      } else if (state.processingState == ProcessingState.buffering) {
        status = PlaybackStatus.buffering;
      } else if (state.processingState == ProcessingState.ready) {
        status = state.playing ? PlaybackStatus.playing : PlaybackStatus.paused;
      } else if (state.processingState == ProcessingState.completed) {
        status = PlaybackStatus.completed;
      } else {
        status = PlaybackStatus.idle;
      }
      this.state = this.state.copyWith(status: status);
    });

    _positionSubscription = _player.positionStream.listen((pos) {
      this.state = this.state.copyWith(position: pos);
    });

    _player.bufferedPositionStream.listen((buf) {
      this.state = this.state.copyWith(bufferedPosition: buf);
    });
  }

  // Aether Pulse: Procedural frequency generator for real-time visual feedback
  void _startVibrancyLoop() {
    _visualizerTimer?.cancel();
    _visualizerTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (state.status == PlaybackStatus.playing) {
        // Generate pseudo-FFT data (16 bands)
        // Highs on the right, Bass on the left
        final List<double> bands = List.generate(16, (index) {
          final double base = (1.0 - (index / 16.0)) * 0.4; // Slightly more power in bass
          return (base + (DateTime.now().millisecond % 1000) / 1000.0 * 0.6).clamp(0.1, 1.0);
        });
        _frequencyController.add(bands);
      } else {
        // Fade to zero when not playing
        _frequencyController.add(List.generate(16, (_) => 0.0));
      }
    });
  }

  Future<void> playSong(SongMetadata song, String sourceUrl) async {
    state = state.copyWith(currentSong: song, status: PlaybackStatus.loading);
    try {
      // Extract YouTube video ID from any format
      String? videoId;
      final uri = Uri.tryParse(sourceUrl);
      if (uri != null && (uri.host.contains('youtube') || uri.host.contains('youtu.be'))) {
        videoId = uri.queryParameters['v'] ?? uri.pathSegments.lastOrNull;
      } else if (!sourceUrl.startsWith('http')) {
        videoId = sourceUrl;
      }

      if (videoId != null && videoId.isNotEmpty) {
        // Use YoutubeAudioSource — pipes bytes through youtube_explode's
        // own authenticated HTTP client. This bypasses the header restriction
        // that causes [just_audio_windows] Media error on raw CDN URLs.
        final source = YoutubeAudioSource(videoId: videoId);
        await _player.setAudioSource(source);
      } else {
        // Fallback: direct URL (for local files or non-YouTube sources)
        await _player.setUrl(sourceUrl);
      }

      _player.play();
    } catch (e) {
      state = state.copyWith(status: PlaybackStatus.error);
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
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _visualizerTimer?.cancel();
    _frequencyController.close();
    _player.dispose();
    super.dispose();
  }
}

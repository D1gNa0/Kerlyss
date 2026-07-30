import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../../../domain/repositories/audio_service_interface.dart';
import '../../../presentation/state/audio_state.dart';
import '../../../core/services/logger_service.dart';
import '../../../main.dart';

class JustAudioService implements AudioServiceInterface {
  final AudioPlayer _player;
  ConcatenatingAudioSource? _activeQueue;
  int _queueLoadToken = 0;

  final _errorController = StreamController<String>.broadcast();
  Stream<String> get errorStream => _errorController.stream;

  JustAudioService() : _player = globalAudioHandler.player {
    _player.playbackEventStream.listen((event) {}, onError: (error, stack) {
      Log.e('JustAudioService: Playback error: $error');
      _errorController.add(error.toString());
    });

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.ready && !state.playing) {
      }
    });

    _player.setVolume(1.0);
  }

  @override
  Stream<PlaybackStatus> get playbackStatusStream {
    return _player.playerStateStream.map((playerState) {
      return switch (playerState.processingState) {
        ProcessingState.idle => PlaybackStatus.idle,
        ProcessingState.loading => PlaybackStatus.loading,
        ProcessingState.buffering => PlaybackStatus.buffering,
        ProcessingState.ready =>
          playerState.playing ? PlaybackStatus.playing : PlaybackStatus.paused,
        ProcessingState.completed => PlaybackStatus.completed,
      };
    });
  }

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;

  @override
  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  bool get playing => _player.playing;

  @override
  Duration get position => _player.position;

  @override
  Duration? get duration => _player.duration;

  @override
  int? get currentIndex => _player.currentIndex;

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position, {int? index}) => _player.seek(position, index: index);

  @override
  Future<void> setUrl(String url, {Map<String, String>? headers, bool play = false}) async {
    Log.d('JustAudioService: setting URL: $url (play: $play)');
    try {
      await _player.setUrl(url, headers: headers);
      if (play) {
        await _player.play();
      }
    } on PlayerInterruptedException {
      Log.d('JustAudioService: setUrl interrupted (expected during rapid switching)');
    }
  }

  @override
  Future<void> setFilePath(String path, {bool play = false}) async {
    Log.d('JustAudioService: setting FilePath: $path (play: $play)');
    try {
      await _player.setFilePath(path);
      if (play) {
        await _player.play();
      }
    } on PlayerInterruptedException {
      Log.d('JustAudioService: setFilePath interrupted (expected during rapid switching)');
    }
  }

  @override
  Stream<int?> get currentIndexStream => _player.currentIndexStream;

  @override
  Future<void> setAudioQueue(List<AudioSource> queue, {int initialIndex = 0, bool play = false}) async {
    Log.d('JustAudioService: setting AudioQueue (${queue.length} items, startAt: $initialIndex)');
    final token = ++_queueLoadToken;
    _activeQueue = ConcatenatingAudioSource(
      children: queue,
      // Pre-load next 2 songs for gapless playback
      useLazyPreparation: true,
    );
    try {
      await _player.setAudioSource(
        _activeQueue!,
        initialIndex: initialIndex,
      );
      if (token != _queueLoadToken) {
        return;
      }
      if (initialIndex > 0 && _player.currentIndex != initialIndex) {
        await _player.seek(Duration.zero, index: initialIndex);
      }
      if (play) {
        await _player.play();
      }
    } on PlayerInterruptedException {
      // Expected during rapid song switching — new call already took over
      Log.d('JustAudioService: Load interrupted (expected during rapid switching)');
    }
  }

  @override
  Future<void> insertIntoQueue(int index, AudioSource source) async {
    if (_activeQueue != null) {
      await _activeQueue!.insert(index, source);
    }
  }

  @override
  Future<void> removeFromQueue(int index) async {
    if (_activeQueue != null && index >= 0 && index < _activeQueue!.length) {
      await _activeQueue!.removeAt(index);
    }
  }

  @override
  Future<void> moveInQueue(int oldIndex, int newIndex) async {
    if (_activeQueue != null) {
      await _activeQueue!.move(oldIndex, newIndex);
    }
  }

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> load(String url, {required SongMetadata metadata}) async {
    await _player.setUrl(url);
  }

  @override
  Future<void> dispose() => _player.dispose();
}

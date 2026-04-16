import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../../../domain/repositories/audio_service_interface.dart';
import '../../../presentation/state/audio_state.dart';

import '../../../main.dart';

class JustAudioService implements AudioServiceInterface {
  final AudioPlayer _player;

  JustAudioService() : _player = globalAudioHandler.player;

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
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setUrl(String url, {Map<String, String>? headers}) => _player.setUrl(url, headers: headers);

  @override
  Future<void> setFilePath(String path) => _player.setFilePath(path);

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> load(String url, {required SongMetadata metadata}) async {
    await _player.setUrl(url);
  }

  @override
  Future<void> dispose() => _player.dispose();
}

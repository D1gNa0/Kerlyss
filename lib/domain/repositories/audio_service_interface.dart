import '../../presentation/state/audio_state.dart';

abstract class AudioServiceInterface {
  Stream<PlaybackStatus> get playbackStatusStream;
  Stream<Duration> get positionStream;
  Stream<Duration> get bufferedPositionStream;
  Stream<Duration?> get durationStream;

  bool get playing;
  Duration get position;
  Duration? get duration;

  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setUrl(String url, {Map<String, String>? headers});
  Future<void> setFilePath(String path);
  Future<void> setVolume(double volume);
  Future<void> load(String url, {required SongMetadata metadata});
  Future<void> dispose();
}

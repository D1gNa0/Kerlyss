import 'package:just_audio/just_audio.dart' show AudioSource;
import '../../presentation/state/audio_state.dart';

abstract class AudioServiceInterface {
  Stream<PlaybackStatus> get playbackStatusStream;
  Stream<Duration> get positionStream;
  Stream<Duration> get bufferedPositionStream;
  Stream<Duration?> get durationStream;

  bool get playing;
  Duration get position;
  Duration? get duration;
  int? get currentIndex;

  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position, {int? index});
  Future<void> setUrl(String url, {Map<String, String>? headers, bool play = false});
  Future<void> setFilePath(String path, {bool play = false});
  
  // Audio Queueing support
  Future<void> setAudioQueue(List<AudioSource> queue, {int initialIndex = 0, bool play = false});
  Future<void> insertIntoQueue(int index, AudioSource source);
  Future<void> removeFromQueue(int index);
  Future<void> moveInQueue(int oldIndex, int newIndex);
  Stream<int?> get currentIndexStream;
  int get queueLength;

  Future<void> setVolume(double volume);
  Future<void> load(String url, {required SongMetadata metadata});
  Future<void> dispose();
}

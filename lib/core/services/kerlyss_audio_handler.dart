import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../../presentation/state/audio_state.dart';

/// Global Audio Handler for Kerlyss.
/// This connects just_audio to the system media controls (Notification, Lock Screen, Desktop).
class KerlyssAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  KerlyssAudioHandler() {
    // 1. Listen for playback state changes from just_audio and push to audio_service
    _player.playbackEventStream.listen(_broadcastState);

    // 2. Listen for current song changes (mapped to MediaItem)
    _player.durationStream.listen((duration) {
      if (mediaItem.value != null) {
        final currentItem = mediaItem.value!;
        mediaItem.add(currentItem.copyWith(duration: duration));
      }
    });

    // Handle session completion (auto-next is handled by AudioNotifier, but we can hook here too)
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        stop();
      }
    });
  }

  // --- Exposed just_audio access for JustAudioService ---
  AudioPlayer get player => _player;

  /// Updates the current media item shown in the system notification.
  void setMediaFromSong(SongMetadata song) {
    mediaItem.add(MediaItem(
      id: song.id,
      album: song.album ?? 'Kerlyss',
      title: song.title,
      artist: song.artist,
      duration: song.duration,
      // Windows SMTC blocks to download remote thumbnails, causing 1-2s delay before playback continues.
      // We purposefully set this to null for now on Windows.
      artUri: null,
    ));
  }

  // --- BaseAudioHandler implementation ---

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() => super.skipToNext(); // Logic handled by AudioNotifier

  @override
  Future<void> skipToPrevious() => super.skipToPrevious(); // Logic handled by AudioNotifier

  /// Broadcasts the current just_audio state to the system.
  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    ));
  }
}

enum PlaybackStatus {
  idle,
  loading,
  buffering,
  ready,
  playing,
  paused,
  completed,
  error
}

enum SourceType { local, youtube, spotify }

class SongMetadata {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? artworkUrl;
  final Duration duration;
  final SourceType source;

  const SongMetadata({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.artworkUrl,
    required this.duration,
    this.source = SourceType.local,
  });

  factory SongMetadata.empty() => const SongMetadata(
        id: '',
        title: 'Not Playing',
        artist: 'Unknown Artist',
        duration: Duration.zero,
      );
}

class AudioState {
  final SongMetadata currentSong;
  final PlaybackStatus status;
  final Duration position;
  final Duration bufferedPosition;
  final bool isShuffleEnabled;
  final bool isRepeatEnabled;

  const AudioState({
    required this.currentSong,
    required this.status,
    required this.position,
    required this.bufferedPosition,
    this.isShuffleEnabled = false,
    this.isRepeatEnabled = false,
  });

  AudioState copyWith({
    SongMetadata? currentSong,
    PlaybackStatus? status,
    Duration? position,
    Duration? bufferedPosition,
    bool? isShuffleEnabled,
    bool? isRepeatEnabled,
  }) {
    return AudioState(
      currentSong: currentSong ?? this.currentSong,
      status: status ?? this.status,
      position: position ?? this.position,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
      isRepeatEnabled: isRepeatEnabled ?? this.isRepeatEnabled,
    );
  }
}

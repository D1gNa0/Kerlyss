import '../../domain/entities/audio_source_type.dart';
import '../../domain/entities/song_entity.dart';

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


class SongMetadata {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? artworkUrl;
  final Duration duration;
  final AudioSourceType source;
  final int? bpm;

  const SongMetadata({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.artworkUrl,
    required this.duration,
    this.source = AudioSourceType.local,
    this.bpm,
  });

  factory SongMetadata.empty() => const SongMetadata(
        id: '',
        title: 'Not Playing',
        artist: 'Unknown Artist',
        duration: Duration.zero,
      );

  /// Centralized conversion from SongEntity to SongMetadata.
  /// Use this everywhere instead of manually mapping fields.
  factory SongMetadata.fromEntity(SongEntity entity) => SongMetadata(
        id: entity.id,
        title: entity.title,
        artist: entity.artist,
        album: entity.album,
        artworkUrl: entity.albumArtUrl,
        duration: entity.duration,
        source: entity.sourceType,
        bpm: entity.bpm,
      );

  SongEntity toEntity() => SongEntity(
        id: id,
        title: title,
        artist: artist,
        album: album ?? 'Unknown Album',
        albumArtUrl: artworkUrl,
        duration: duration,
        sourceUrl: id, // Mapping ID to sourceUrl for consistency
        sourceType: source,
        bpm: bpm,
        dateAdded: DateTime.now(),
      );
}


class AudioState {
  final SongMetadata currentSong;
  final PlaybackStatus status;
  final Duration position;
  final Duration bufferedPosition;
  final bool isShuffleEnabled;
  final bool isRepeatEnabled;
  final List<SongMetadata> playlist;
  final int currentIndex;

  final double volume;

  const AudioState({
    required this.currentSong,
    required this.status,
    required this.position,
    required this.bufferedPosition,
    this.isShuffleEnabled = false,
    this.isRepeatEnabled = false,
    this.playlist = const [],
    this.currentIndex = -1,
    this.volume = 1.0,
  });

  AudioState copyWith({
    SongMetadata? currentSong,
    PlaybackStatus? status,
    Duration? position,
    Duration? bufferedPosition,
    bool? isShuffleEnabled,
    bool? isRepeatEnabled,
    List<SongMetadata>? playlist,
    int? currentIndex,
    double? volume,
  }) {
    return AudioState(
      currentSong: currentSong ?? this.currentSong,
      status: status ?? this.status,
      position: position ?? this.position,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
      isRepeatEnabled: isRepeatEnabled ?? this.isRepeatEnabled,
      playlist: playlist ?? this.playlist,
      currentIndex: currentIndex ?? this.currentIndex,
      volume: volume ?? this.volume,
    );
  }
}


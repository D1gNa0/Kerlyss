import 'audio_source_type.dart';

class SongEntity {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String? albumArtUrl;
  final Duration duration;
  final String sourceUrl; // YouTube Stream URI or Local File Path
  final AudioSourceType sourceType;
  final String? localPath;
  final int? bpm;
  final DateTime dateAdded;

  const SongEntity({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.albumArtUrl,
    required this.duration,
    required this.sourceUrl,
    required this.sourceType,
    this.localPath,
    this.bpm,
    required this.dateAdded,
  });

  SongEntity copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? albumArtUrl,
    Duration? duration,
    String? sourceUrl,
    AudioSourceType? sourceType,
    String? localPath,
    int? bpm,
    DateTime? dateAdded,
  }) {
    return SongEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumArtUrl: albumArtUrl ?? this.albumArtUrl,
      duration: duration ?? this.duration,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourceType: sourceType ?? this.sourceType,
      localPath: localPath ?? this.localPath,
      bpm: bpm ?? this.bpm,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }


  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SongEntity{id: $id, title: $title, artist: $artist, album: $album, sourceType: $sourceType}';
  }
}

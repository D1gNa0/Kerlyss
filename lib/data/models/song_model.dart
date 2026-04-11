import 'package:isar/isar.dart';
import '../../domain/entities/song_entity.dart';
import '../../domain/entities/audio_source_type.dart';

part 'song_model.g.dart';

@collection
class SongModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String songId;

  late String title;
  late String artist;
  late String album;
  String? albumArtUrl;
  late int durationMs;
  late String sourceUrl;
  
  @enumerated
  late AudioSourceType sourceType;

  bool isFavorite = false;
  
  String? localPath;


  SongEntity toEntity() {
    return SongEntity(
      id: songId,
      title: title,
      artist: artist,
      album: album,
      albumArtUrl: albumArtUrl,
      duration: Duration(milliseconds: durationMs),
      sourceUrl: sourceUrl,
      sourceType: sourceType,
    );
  }

  static SongModel fromEntity(SongEntity entity) {
    return SongModel()
      ..songId = entity.id
      ..title = entity.title
      ..artist = entity.artist
      ..album = entity.album
      ..albumArtUrl = entity.albumArtUrl
      ..durationMs = entity.duration.inMilliseconds
      ..sourceUrl = entity.sourceUrl
      ..sourceType = entity.sourceType
      ..localPath = null; // New models start with no local path
  }
}


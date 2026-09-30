import 'package:isar/isar.dart';
import '../../domain/entities/playlist_entity.dart';

part 'playlist_model.g.dart';

@collection
class PlaylistModel {
  Id id = Isar.autoIncrement;

  @Index()
  String? uuid;

  @Index()
  late String name;

  late List<String> songIds;
  
  DateTime createdAt = DateTime.now();

  @Index()
  DateTime? updatedAt;

  @Index()
  bool isDeleted = false;

  DateTime? deletedAt;

  bool isRealtimeSynced = false;

  bool autoDownloadNewTracks = false;

  String? spotifySourceUrl;

  String? coverArtUrl;

  DateTime? lastSyncedAt;

  PlaylistEntity toEntity() {
    return PlaylistEntity(
      id: id == Isar.autoIncrement ? null : id,
      uuid: uuid,
      name: name,
      songIds: songIds,
      createdAt: createdAt,
      updatedAt: updatedAt ?? createdAt,
      isDeleted: isDeleted,
      deletedAt: deletedAt,
      isRealtimeSynced: isRealtimeSynced,
      autoDownloadNewTracks: autoDownloadNewTracks,
      spotifySourceUrl: spotifySourceUrl,
      coverArtUrl: coverArtUrl,
      lastSyncedAt: lastSyncedAt,
    );
  }

  static PlaylistModel fromEntity(PlaylistEntity entity) {
    final model = PlaylistModel()
      ..uuid = entity.uuid
      ..name = entity.name
      ..songIds = entity.songIds
      ..createdAt = entity.createdAt
      ..updatedAt = entity.updatedAt ?? entity.createdAt
      ..isDeleted = entity.isDeleted
      ..deletedAt = entity.deletedAt
      ..isRealtimeSynced = entity.isRealtimeSynced
      ..autoDownloadNewTracks = entity.autoDownloadNewTracks
      ..spotifySourceUrl = entity.spotifySourceUrl
      ..coverArtUrl = entity.coverArtUrl
      ..lastSyncedAt = entity.lastSyncedAt;
    if (entity.id != null) {
      model.id = entity.id!;
    }
    return model;
  }
}

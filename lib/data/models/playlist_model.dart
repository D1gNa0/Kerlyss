import 'package:isar/isar.dart';
import '../../domain/entities/playlist_entity.dart';

part 'playlist_model.g.dart';

@collection
class PlaylistModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String name;

  late List<String> songIds;
  
  DateTime createdAt = DateTime.now();

  bool isRealtimeSynced = false;

  bool autoDownloadNewTracks = false;

  String? spotifySourceUrl;

  String? coverArtUrl;

  DateTime? lastSyncedAt;

  PlaylistEntity toEntity() {
    return PlaylistEntity(
      id: id == Isar.autoIncrement ? null : id,
      name: name,
      songIds: songIds,
      createdAt: createdAt,
      isRealtimeSynced: isRealtimeSynced,
      autoDownloadNewTracks: autoDownloadNewTracks,
      spotifySourceUrl: spotifySourceUrl,
      coverArtUrl: coverArtUrl,
      lastSyncedAt: lastSyncedAt,
    );
  }

  static PlaylistModel fromEntity(PlaylistEntity entity) {
    final model = PlaylistModel()
      ..name = entity.name
      ..songIds = entity.songIds
      ..createdAt = entity.createdAt
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

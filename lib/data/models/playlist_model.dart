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

  PlaylistEntity toEntity() {
    return PlaylistEntity(
      id: id == Isar.autoIncrement ? null : id,
      name: name,
      songIds: songIds,
      createdAt: createdAt,
    );
  }

  static PlaylistModel fromEntity(PlaylistEntity entity) {
    final model = PlaylistModel()
      ..name = entity.name
      ..songIds = entity.songIds
      ..createdAt = entity.createdAt;
    if (entity.id != null) {
      model.id = entity.id!;
    }
    return model;
  }
}

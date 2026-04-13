import 'package:isar/isar.dart';

part 'playlist_model.g.dart';

@collection
class PlaylistModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String name;

  late List<String> songIds;
  
  DateTime createdAt = DateTime.now();
}

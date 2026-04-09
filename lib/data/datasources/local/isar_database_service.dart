import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/song_model.dart';

class IsarDatabaseService {
  late Isar isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [SongModelSchema],
      directory: dir.path,
    );
  }

  Future<void> saveSong(SongModel song) async {
    await isar.writeTxn(() async {
      await isar.songModels.put(song);
    });
  }

  Future<List<SongModel>> getAllSongs() async {
    return await isar.songModels.where().findAll();
  }

  Future<List<SongModel>> getFavorites() async {
    return await isar.songModels.filter().isFavoriteEqualTo(true).findAll();
  }

  Future<void> deleteSong(String songId) async {
    await isar.writeTxn(() async {
      await isar.songModels.filter().songIdEqualTo(songId).deleteAll();
    });
  }
}

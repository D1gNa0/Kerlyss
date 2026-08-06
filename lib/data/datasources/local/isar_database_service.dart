import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/song_model.dart';
import '../../models/playlist_model.dart';
import '../../models/cached_search_model.dart';
import '../../models/app_settings_model.dart';

class IsarDatabaseService {
  late Isar isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [SongModelSchema, PlaylistModelSchema, CachedSearchModelSchema, AppSettingsModelSchema],
      directory: dir.path,
    );
  }

  // --- Song Operations ---

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

  Future<SongModel?> getSongById(String songId) async {
    return await isar.songModels.filter().songIdEqualTo(songId).findFirst();
  }

  Future<List<SongModel>> getSongsByIds(List<String> songIds) async {
    if (songIds.isEmpty) return [];
    return await isar.songModels.filter().anyOf(songIds, (q, id) => q.songIdEqualTo(id)).findAll();
  }

  Future<void> updateLocalPath(SongModel songData, String? localPath) async {
    await isar.writeTxn(() async {
      final existing = await isar.songModels.filter().songIdEqualTo(songData.songId).findFirst();
      if (existing != null) {
        existing.localPath = localPath;
        await isar.songModels.put(existing);
      } else {
        songData.localPath = localPath;
        await isar.songModels.put(songData);
      }
    });
  }

  // --- Playlist Operations ---
  Future<void> savePlaylist(PlaylistModel playlist) async {
    await isar.writeTxn(() async {
      await isar.playlistModels.put(playlist);
    });
  }

  Future<List<PlaylistModel>> getAllPlaylists() async {
    return await isar.playlistModels.where().findAll();
  }

  Future<void> deletePlaylist(int id) async {
    await isar.writeTxn(() async {
      await isar.playlistModels.delete(id);
    });
  }

  Future<PlaylistModel?> getPlaylistById(int id) async {
    return await isar.playlistModels.get(id);
  }

  // --- Search Cache Operations ---
  Future<CachedSearchModel?> getCachedSearch(String query) async {
    final normalized = CachedSearchModel.normalizeQuery(query);
    final cached = await isar.cachedSearchModels
        .filter()
        .queryEqualTo(normalized)
        .findFirst();
    return cached;
  }

  Future<void> cacheSearch(String query, String resultsJson, {int ttlMinutes = 60}) async {
    final normalized = CachedSearchModel.normalizeQuery(query);
    await isar.writeTxn(() async {
      // Remove old cache entry if exists
      await isar.cachedSearchModels.filter().queryEqualTo(normalized).deleteAll();

      final cacheEntry = CachedSearchModel()
        ..query = normalized
        ..resultsJson = resultsJson
        ..cachedAt = DateTime.now()
        ..ttlMinutes = ttlMinutes;

      await isar.cachedSearchModels.put(cacheEntry);
    });

    // Periodic cleanup of expired entries
    await _cleanupExpiredSearches();
  }

  Future<void> _cleanupExpiredSearches() async {
    // Run cleanup occasionally (every 10th call roughly)
    if (DateTime.now().second % 10 != 0) return;

    await isar.writeTxn(() async {
      final expiredThreshold = DateTime.now().subtract(const Duration(hours: 1));
      await isar.cachedSearchModels
          .filter()
          .cachedAtLessThan(expiredThreshold)
          .deleteAll();
    });
  }

  Future<void> clearSearchCache() async {
    await isar.writeTxn(() async {
      await isar.cachedSearchModels.clear();
    });
  }

  // --- Settings Operations ---
  Future<AppSettingsModel> getSettings() async {
    final settings = await isar.appSettingsModels.get(1);
    return settings ?? AppSettingsModel();
  }

  Future<void> saveSettings(AppSettingsModel settings) async {
    settings.id = 1;
    await isar.writeTxn(() async {
      await isar.appSettingsModels.put(settings);
    });
  }
}



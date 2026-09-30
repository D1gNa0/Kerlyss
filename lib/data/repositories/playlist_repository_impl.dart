import '../../domain/repositories/playlist_repository.dart';
import '../datasources/local/isar_database_service.dart';
import '../models/playlist_model.dart';
import '../../core/services/logger_service.dart';
import '../../core/utils/uuid_generator.dart';
import '../../domain/entities/playlist_entity.dart';

class PlaylistRepositoryImpl implements PlaylistRepository {
  final IsarDatabaseService _dbService;

  PlaylistRepositoryImpl(this._dbService);

  @override
  Future<void> createPlaylist(
    String name,
    List<String> songIds, {
    String? uuid,
    bool isRealtimeSynced = false,
    bool autoDownloadNewTracks = false,
    String? spotifySourceUrl,
    String? coverArtUrl,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final playlist = PlaylistModel()
        ..uuid = uuid ?? UuidGenerator.generate()
        ..name = name
        ..songIds = songIds
        ..createdAt = now
        ..updatedAt = now
        ..isDeleted = false
        ..isRealtimeSynced = isRealtimeSynced
        ..autoDownloadNewTracks = autoDownloadNewTracks
        ..spotifySourceUrl = spotifySourceUrl
        ..coverArtUrl = coverArtUrl
        ..lastSyncedAt = DateTime.now();
      await _dbService.savePlaylist(playlist);
    } catch (e, stack) {
      Log.e('PlaylistRepositoryImpl: createPlaylist failed: $e', e, stack);
      rethrow;
    }
  }

  @override
  Future<List<PlaylistEntity>> getAllPlaylists() async {
    try {
      final models = await _dbService.getAllPlaylists();
      final entities = <PlaylistEntity>[];
      for (final m in models) {
        if (m.uuid == null || m.uuid!.isEmpty) {
          m.uuid = UuidGenerator.generate();
          await _dbService.savePlaylist(m);
        }
        entities.add(m.toEntity());
      }
      return entities;
    } catch (e, stack) {
      Log.e('PlaylistRepositoryImpl: getAllPlaylists failed: $e', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> deletePlaylist(int id) async {
    try {
      await _dbService.deletePlaylist(id);
    } catch (e, stack) {
      Log.e('PlaylistRepositoryImpl: deletePlaylist failed: $e', e, stack);
      rethrow;
    }
  }

  @override
  Future<PlaylistEntity?> getPlaylistById(int id) async {
    try {
      final model = await _dbService.getPlaylistById(id);
      if (model == null || model.isDeleted) return null;
      return model.toEntity();
    } catch (e, stack) {
      Log.e('PlaylistRepositoryImpl: getPlaylistById failed: $e', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> savePlaylist(PlaylistEntity playlist) async {
    try {
      final model = PlaylistModel.fromEntity(playlist);
      await _dbService.savePlaylist(model);
    } catch (e, stack) {
      Log.e('PlaylistRepositoryImpl: savePlaylist failed: $e', e, stack);
      rethrow;
    }
  }
}

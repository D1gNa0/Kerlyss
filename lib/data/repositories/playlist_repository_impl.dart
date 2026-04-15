import '../../domain/repositories/playlist_repository.dart';
import '../datasources/local/isar_database_service.dart';
import '../models/playlist_model.dart';

class PlaylistRepositoryImpl implements PlaylistRepository {
  final IsarDatabaseService _dbService;

  PlaylistRepositoryImpl(this._dbService);

  @override
  Future<void> createPlaylist(String name, List<String> songIds) async {
    final playlist = PlaylistModel()
      ..name = name
      ..songIds = songIds;
    await _dbService.savePlaylist(playlist);
  }

  @override
  Future<List<PlaylistModel>> getAllPlaylists() async {
    return await _dbService.getAllPlaylists();
  }

  @override
  Future<void> deletePlaylist(int id) async {
    await _dbService.deletePlaylist(id);
  }

  @override
  Future<PlaylistModel?> getPlaylistById(int id) async {
    return await _dbService.getPlaylistById(id);
  }
}

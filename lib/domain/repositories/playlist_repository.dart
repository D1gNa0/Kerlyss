import '../../data/models/playlist_model.dart';

abstract class PlaylistRepository {
  Future<void> createPlaylist(String name, List<String> songIds);
  Future<List<PlaylistModel>> getAllPlaylists();
  Future<void> deletePlaylist(int id);
  Future<PlaylistModel?> getPlaylistById(int id);
}

import '../entities/playlist_entity.dart';

abstract class PlaylistRepository {
  Future<void> createPlaylist(String name, List<String> songIds);
  Future<List<PlaylistEntity>> getAllPlaylists();
  Future<void> deletePlaylist(int id);
  Future<PlaylistEntity?> getPlaylistById(int id);
  Future<void> savePlaylist(PlaylistEntity playlist);
}

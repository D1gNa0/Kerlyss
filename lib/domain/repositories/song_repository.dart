import '../entities/song_entity.dart';

abstract class SongRepository {
  /// Fetches all songs from local storage.
  Future<List<SongEntity>> getLocalSongs();

  /// Searches for songs on Spotify/YouTube based on a query.
  Future<List<SongEntity>> searchSongs(String query);

  /// Saves a song to favorites (Isar).
  Future<void> addToFavorites(SongEntity song);

  /// Removes a song from favorites.
  Future<void> removeFromFavorites(String id);

  /// Fetches favorite songs.
  Future<List<SongEntity>> getFavorites();

  /// Resolves the direct stream URI for a song (e.g. YouTube stream).
  Future<String> resolveStreamUri(String songId);

  /// Resolves metadata from a Spotify URL and mirrors it to a YouTube stream.
  Future<SongEntity> getSongFromSpotifyUrl(String url);
}

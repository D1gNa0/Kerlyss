import '../../data/models/spotify_playlist_model.dart';
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

  /// Fetches all songs in the library.
  Future<List<SongEntity>> getAllSongs();


  /// Resolves the direct stream URI for a song (e.g. YouTube stream) using background resolution if necessary.
  Future<String> resolveStreamUri(SongEntity song);

  /// Resolves metadata from a Spotify URL and mirrors it to a YouTube stream.
  Future<SongEntity> getSongFromSpotifyUrl(String url);

  /// Saves or updates song metadata without necessarily marking as favorite.
  Future<void> saveSong(SongEntity song);

  /// Fetches a song by its unique ID.
  Future<SongEntity?> getSongById(String id);

  /// Scrapes a Spotify playlist link for tracks.
  Future<SpotifyPlaylistModel> getPlaylistFromSpotifyUrl(String url);

  /// Resolves a single text query into a best-match SongEntity.
  Future<SongEntity?> resolveQueryToSong(String query);

  /// Fetches the BPM for a song remotely.
  Future<int?> fetchBpmRemotely(SongEntity song);

  /// Updates the BPM of a specific song in local storage.
  Future<void> updateBpm(String id, int bpm);
}


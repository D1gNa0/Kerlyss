import '../models/spotify_playlist_model.dart';
import '../../domain/entities/song_entity.dart';
import '../../domain/repositories/song_repository.dart';
import '../datasources/local/isar_database_service.dart';
import '../datasources/remote/spotify_public_service.dart';
import '../datasources/remote/youtube_audio_engine.dart';
import '../datasources/remote/search_aggregator.dart';
import '../models/song_model.dart';
import '../../domain/entities/audio_source_type.dart';

class SongRepositoryImpl implements SongRepository {
  final IsarDatabaseService _localDataSource;
  final SpotifyPublicService _spotifyPublicService;
  final YoutubeAudioEngine _youtubeAudioEngine;
  final SearchAggregator _searchAggregator;

  SongRepositoryImpl(
    this._localDataSource,
    this._spotifyPublicService,
    this._youtubeAudioEngine,
    this._searchAggregator,
  );

  @override
  Future<List<SongEntity>> getLocalSongs() async {
    final models = await _localDataSource.getAllSongs();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<SongEntity>> searchSongs(String query) async {
    // Aggregated search logic merging Spotify and YouTube
    return await _searchAggregator.search(query);
  }

  @override
  Future<void> addToFavorites(SongEntity song) async {
    final existing = await _localDataSource.getSongById(song.id);
    final model = SongModel.fromEntity(song)..isFavorite = true;
    
    if (existing != null) {
      model.dateAdded = existing.dateAdded; // Preserve original add date
      model.localPath = existing.localPath; // Preserve download path
    }
    
    await _localDataSource.saveSong(model);
  }

  @override
  Future<void> removeFromFavorites(String id) async {
    final existing = await _localDataSource.getSongById(id);
    if (existing != null) {
      existing.isFavorite = false;
      await _localDataSource.saveSong(existing);
    }
  }


  @override
  Future<List<SongEntity>> getFavorites() async {
    final models = await _localDataSource.getFavorites();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<SongEntity>> getAllSongs() async {
    final models = await _localDataSource.getAllSongs();
    return models.map((m) => m.toEntity()).toList();
  }


  @override
  Future<String> resolveStreamUri(String songId) async {
    return await _youtubeAudioEngine.getStreamUri(songId);
  }

  @override
  Future<SongEntity> getSongFromSpotifyUrl(String url) async {
    // 1. Fetch Metadata from public oEmbed
    final metadata = await _spotifyPublicService.fetchMetadata(url);
    final String fullTitle = metadata.title;
    final String artworkUrl = metadata.thumbnailUrl;
    final String spotifyId = _spotifyPublicService.extractId(url) ?? 'spotify_${fullTitle.hashCode}';

    // 2. Mirror to YouTube: Search with "Track Name - Artist Name"
    final results = await searchSongs(fullTitle);
    
    if (results.isEmpty) {
      throw Exception('Could not find a YouTube mirror for: $fullTitle');
    }

    final topMatch = results.firstWhere(
      (song) => song.sourceType == AudioSourceType.youtube,
      orElse: () => results.firstWhere(
        (song) => song.sourceUrl.isNotEmpty,
        orElse: () => results.first,
      ),
    );

    // 3. Construct a Hybrid Entity (Spotify Identity + YouTube Stream)
    return SongEntity(
      id: spotifyId,
      title: topMatch.title, // Keep YouTube title as it's more accurate for search results
      artist: topMatch.artist,
      album: 'Spotify Mirror',
      albumArtUrl: artworkUrl, // Use Spotify high-res artwork
      duration: topMatch.duration,
      sourceUrl: topMatch.sourceUrl, // YouTube Stream ID
      sourceType: AudioSourceType.spotify,
      dateAdded: DateTime.now(),
    );
  }

  @override
  Future<void> saveSong(SongEntity song) async {
    final model = SongModel.fromEntity(song);
    // Preserving favorite status if it already exists
    final existing = await _localDataSource.getSongById(song.id);
    if (existing != null) {
      model.isFavorite = existing.isFavorite;
      model.localPath = existing.localPath;
      model.dateAdded = existing.dateAdded; // Preserve original add date
    }
    await _localDataSource.saveSong(model);
  }

  @override
  Future<SongEntity?> getSongById(String id) async {
    final model = await _localDataSource.getSongById(id);
    return model?.toEntity();
  }

  @override
  Future<SpotifyPlaylistModel> getPlaylistFromSpotifyUrl(String url) async {
    return await _spotifyPublicService.extractPlaylistData(url);
  }

  @override
  Future<SongEntity?> resolveQueryToSong(String query) async {
    final results = await searchSongs(query);
    if (results.isEmpty) return null;

    // Pick the best match (prioritize YouTube streams for raw queries)
    return results.firstWhere(
      (song) => song.sourceType == AudioSourceType.youtube,
      orElse: () => results.firstWhere(
        (song) => song.sourceUrl.isNotEmpty,
        orElse: () => results.first,
      ),
    );
  }

}


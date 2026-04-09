import '../../domain/entities/song_entity.dart';
import '../../domain/repositories/song_repository.dart';
import '../datasources/local/isar_database_service.dart';
import '../datasources/remote/spotify_public_service.dart';
import '../datasources/remote/youtube_audio_engine.dart';
import '../datasources/remote/youtube_service.dart';
import '../datasources/remote/search_aggregator.dart';
import '../models/song_model.dart';
import '../../domain/entities/audio_source_type.dart';

class SongRepositoryImpl implements SongRepository {
  final IsarDatabaseService _localDataSource;
  final SpotifyPublicService _spotifyPublicService;
  final YoutubeService _youtubeService;
  final YoutubeAudioEngine _youtubeAudioEngine;
  final SearchAggregator _searchAggregator;

  SongRepositoryImpl(
    this._localDataSource,
    this._spotifyPublicService,
    this._youtubeService,
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
    final model = SongModel.fromEntity(song)..isFavorite = true;
    await _localDataSource.saveSong(model);
  }

  @override
  Future<void> removeFromFavorites(String id) async {
    await _localDataSource.deleteSong(id);
  }

  @override
  Future<List<SongEntity>> getFavorites() async {
    final models = await _localDataSource.getFavorites();
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
    final String fullTitle = metadata['title'] ?? 'Unknown Track';
    final String artworkUrl = metadata['thumbnail_url'];
    final String spotifyId = _spotifyPublicService.extractId(url) ?? 'spotify_${fullTitle.hashCode}';

    // 2. Mirror to YouTube: Search with "Track Name - Artist Name"
    final results = await searchSongs(fullTitle);
    
    if (results.isEmpty) {
      throw Exception('Could not find a YouTube mirror for: $fullTitle');
    }

    final topMatch = results.first;

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
    );
  }
}

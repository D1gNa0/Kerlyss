import '../../domain/entities/song_entity.dart';
import '../../domain/repositories/song_repository.dart';
import '../datasources/local/isar_database_service.dart';
import '../datasources/remote/spotify_metadata_service.dart';
import '../datasources/remote/youtube_audio_engine.dart';
import '../datasources/remote/youtube_service.dart';
import '../models/song_model.dart';
import '../../domain/entities/audio_source_type.dart';

class SongRepositoryImpl implements SongRepository {
  final IsarDatabaseService _localDataSource;
  final SpotifyMetadataService _remoteDataSource;
  final YoutubeService _youtubeService;
  final YoutubeAudioEngine _youtubeAudioEngine;

  SongRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
    this._youtubeService,
    this._youtubeAudioEngine,
  );

  @override
  Future<List<SongEntity>> getLocalSongs() async {
    final models = await _localDataSource.getAllSongs();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<SongEntity>> searchSongs(String query) async {
    // 1. Search YouTube
    final ytVideos = await _youtubeService.searchVideos(query);

    // 2. Map YouTube videos to SongEntity
    return ytVideos.map((v) {
      return SongEntity(
        id: v.id.value,
        title: v.title,
        artist: v.author,
        album: 'YouTube',
        albumArtUrl: v.thumbnails.highResUrl,
        duration: v.duration!,
        sourceUrl: 'https://www.youtube.com/watch?v=${v.id.value}',
        sourceType: AudioSourceType.youtube,
      );
    }).toList();
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
    // Logic: If YouTube ID, resolve via YoutubeAudioEngine (Tiered Cache)
    return await _youtubeAudioEngine.getStreamUri(songId);
  }
}

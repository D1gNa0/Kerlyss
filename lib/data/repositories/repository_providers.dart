import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/local/isar_database_service.dart';
import '../datasources/remote/spotify_metadata_service.dart';
import '../datasources/remote/youtube_service.dart';
import '../datasources/remote/youtube_audio_engine.dart';
import 'song_repository_impl.dart';
import '../../domain/repositories/song_repository.dart';

// Data Sources
final isarDatabaseServiceProvider = Provider((ref) => IsarDatabaseService());

final dioProvider = Provider((ref) => Dio());

final spotifyMetadataServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return SpotifyMetadataService(dio);
});

final youtubeServiceProvider = Provider((ref) {
  final service = YoutubeService();
  ref.onDispose(() => service.close());
  return service;
});

final youtubeAudioEngineProvider = Provider((ref) {
  final youtubeService = ref.watch(youtubeServiceProvider);
  return YoutubeAudioEngine(youtubeService);
});

// Repositories
final songRepositoryProvider = Provider<SongRepository>((ref) {
  final localDataSource = ref.watch(isarDatabaseServiceProvider);
  final remoteDataSource = ref.watch(spotifyMetadataServiceProvider);
  final youtubeService = ref.watch(youtubeServiceProvider);
  final youtubeAudioEngine = ref.watch(youtubeAudioEngineProvider);

  return SongRepositoryImpl(
    localDataSource,
    remoteDataSource,
    youtubeService,
    youtubeAudioEngine,
  );
});

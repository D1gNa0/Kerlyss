import '../../domain/repositories/playlist_repository.dart';
import 'playlist_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/local/isar_database_service.dart';
import '../datasources/remote/jamendo_service.dart';
import '../datasources/remote/spotify_public_service.dart';
import '../datasources/remote/youtube_service.dart';
import '../datasources/remote/youtube_audio_engine.dart';
import '../datasources/remote/search_aggregator.dart';
import '../datasources/remote/bpm_scraper_service.dart';
import '../datasources/remote/deezer_public_service.dart';
import 'song_repository_impl.dart';
import '../../domain/repositories/song_repository.dart';
import '../../core/services/logger_service.dart';

// Data Sources
final isarDatabaseServiceProvider = Provider((ref) => IsarDatabaseService());

/// Configured Dio instance with connection pooling and reasonable defaults.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 15),
  ));

  // Add logging interceptor for debugging
  dio.interceptors.add(LogInterceptor(
    requestBody: false,
    responseBody: false,
    error: true,
    logPrint: (o) => Log.d('[Dio] $o'),
  ));

  ref.onDispose(dio.close);

  return dio;
});

final spotifyPublicServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return SpotifyPublicService(dio);
});

final jamendoServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return JamendoService(dio);
});

final youtubeServiceProvider = Provider((ref) {
  final service = YoutubeService();
  ref.onDispose(service.close);
  return service;
});


final youtubeAudioEngineProvider = Provider((ref) {
  final youtubeService = ref.watch(youtubeServiceProvider);
  return YoutubeAudioEngine(youtubeService);
});

final deezerPublicServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return DeezerPublicService(dio);
});

final searchAggregatorProvider = Provider((ref) {
  final deezerService = ref.watch(deezerPublicServiceProvider);
  final isarService = ref.watch(isarDatabaseServiceProvider);
  return SearchAggregator(deezerService, isarService: isarService);
});

// Repositories
final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  final localDataSource = ref.watch(isarDatabaseServiceProvider);
  return PlaylistRepositoryImpl(localDataSource);
});

final bpmScraperServiceProvider = Provider<BpmScraperService>((ref) {
  final dio = ref.watch(dioProvider);
  return BpmScraperService(dio);
});

final songRepositoryProvider = Provider<SongRepository>((ref) {
  final localDataSource = ref.watch(isarDatabaseServiceProvider);
  final spotifyPublicService = ref.watch(spotifyPublicServiceProvider);
  final youtubeAudioEngine = ref.watch(youtubeAudioEngineProvider);
  final youtubeService = ref.watch(youtubeServiceProvider);
  final searchAggregator = ref.watch(searchAggregatorProvider);
  final bpmScraperService = ref.watch(bpmScraperServiceProvider);

  return SongRepositoryImpl(
    localDataSource,
    spotifyPublicService,
    youtubeAudioEngine,
    youtubeService,
    searchAggregator,
    bpmScraperService,
  );
});

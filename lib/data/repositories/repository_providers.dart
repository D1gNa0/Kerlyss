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

// Data Sources
final isarDatabaseServiceProvider = Provider((ref) => IsarDatabaseService());

final dioProvider = Provider((ref) => Dio());

final spotifyPublicServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return SpotifyPublicService(dio);
});

final jamendoServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return JamendoService(dio);
});

final youtubeServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  final service = YoutubeService(dio);
  ref.onDispose(() => service.close());
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
  return SearchAggregator(deezerService);
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

final songRepositoryProvider = Provider<SongRepositoryImpl>((ref) {
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

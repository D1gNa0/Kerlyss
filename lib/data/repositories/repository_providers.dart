import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/local/isar_database_service.dart';
import '../datasources/remote/jamendo_service.dart';
import '../datasources/remote/spotify_public_service.dart';
import '../datasources/remote/youtube_service.dart';
import '../datasources/remote/youtube_audio_engine.dart';
import '../datasources/remote/search_aggregator.dart';
import 'song_repository_impl.dart';
import '../../domain/repositories/song_repository.dart';

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

final searchAggregatorProvider = Provider((ref) {
  final spotifyService = ref.watch(spotifyPublicServiceProvider);
  final youtubeService = ref.watch(youtubeServiceProvider);
  final jamendoService = ref.watch(jamendoServiceProvider);
  return SearchAggregator(spotifyService, youtubeService, jamendoService);
});

// Repositories
final songRepositoryProvider = Provider<SongRepository>((ref) {
  final localDataSource = ref.watch(isarDatabaseServiceProvider);
  final spotifyPublicService = ref.watch(spotifyPublicServiceProvider);
  final youtubeAudioEngine = ref.watch(youtubeAudioEngineProvider);
  final searchAggregator = ref.watch(searchAggregatorProvider);

  return SongRepositoryImpl(
    localDataSource,
    spotifyPublicService,
    youtubeAudioEngine,
    searchAggregator,
  );
});

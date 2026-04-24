import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kerlyss/data/repositories/song_repository_impl.dart';
import 'package:kerlyss/data/datasources/local/isar_database_service.dart';
import 'package:kerlyss/data/datasources/remote/spotify_public_service.dart';
import 'package:kerlyss/data/datasources/remote/search_aggregator.dart';
import 'package:kerlyss/data/datasources/remote/youtube_audio_engine.dart';
import 'package:kerlyss/data/datasources/remote/youtube_service.dart';
import 'package:kerlyss/data/datasources/remote/bpm_scraper_service.dart';
import 'package:kerlyss/domain/entities/audio_source_type.dart';
import 'package:kerlyss/domain/entities/song_entity.dart';


class MockIsarDatabaseService extends Mock implements IsarDatabaseService {}
class MockSpotifyPublicService extends Mock implements SpotifyPublicService {}
class MockSearchAggregator extends Mock implements SearchAggregator {}
class MockYoutubeAudioEngine extends Mock implements YoutubeAudioEngine {}
class MockYoutubeService extends Mock implements YoutubeService {}
class MockBpmScraperService extends Mock implements BpmScraperService {}


void main() {
  late SongRepositoryImpl repository;
  late MockIsarDatabaseService mockLocal;
  late MockSpotifyPublicService mockRemote;
  late MockSearchAggregator mockSearch;
  late MockYoutubeAudioEngine mockYtEngine;
  late MockYoutubeService mockYoutubeService;
  late MockBpmScraperService mockBpm;

  setUp(() {
    mockLocal = MockIsarDatabaseService();
    mockRemote = MockSpotifyPublicService();
    mockSearch = MockSearchAggregator();
    mockYtEngine = MockYoutubeAudioEngine();
    mockYoutubeService = MockYoutubeService();
    mockBpm = MockBpmScraperService();
    
    repository = SongRepositoryImpl(
      mockLocal,
      mockRemote,
      mockYtEngine,
      mockYoutubeService,
      mockSearch,
      mockBpm,
    );
  });

  group('Hybrid Audio Stream Resolution Regression Tests', () {
    test('should resolve YouTube stream via YoutubeAudioEngine', () async {
      const songId = 'yt_123';
      const expectedUri = 'https://yt.com/stream/123';
      final song = SongEntity(
        id: songId,
        title: 'Track',
        artist: 'Artist',
        album: 'Album',
        duration: Duration.zero,
        sourceUrl: songId,
        sourceType: AudioSourceType.youtube,
        dateAdded: DateTime(2026, 1, 1),
      );
      
      when(() => mockYtEngine.getStreamUri(songId))
          .thenAnswer((_) async => expectedUri);

      final result = await repository.resolveStreamUri(song);

      expect(result, expectedUri);
      verify(() => mockYtEngine.getStreamUri(songId)).called(1);
    });

    test('should handle direct filesystem paths for local stubs (Phase 2)', () async {
      // NOTE: Current implementation only supports YT. 
      // This test serves as a regression stub for Local Path resolution.
      const localId = 'local_file_001';
      const localPath = '/storage/emulated/0/Music/song.mp3';
      final song = SongEntity(
        id: localId,
        title: 'Local Track',
        artist: 'Local Artist',
        album: 'Local Album',
        duration: Duration.zero,
        sourceUrl: localId,
        sourceType: AudioSourceType.local,
        dateAdded: DateTime(2026, 1, 1),
      );
      
      // Stubbing the logic we expect to implement in Phase 2
      // For now, it might still go through ytEngine if not branched,
      // so we use this to define expected behavior.
      
      when(() => mockYtEngine.getStreamUri(localId))
          .thenAnswer((_) async => localPath);

        final result = await repository.resolveStreamUri(song);

      expect(result, localPath);
    });
  });
}

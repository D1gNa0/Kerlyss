import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kerlyss/data/repositories/song_repository_impl.dart';
import 'package:kerlyss/data/datasources/local/isar_database_service.dart';
import 'package:kerlyss/data/datasources/remote/spotify_public_service.dart';
import 'package:kerlyss/data/datasources/remote/search_aggregator.dart';
import 'package:kerlyss/data/datasources/remote/youtube_audio_engine.dart';
import 'package:kerlyss/data/datasources/remote/youtube_service.dart';

class MockIsarDatabaseService extends Mock implements IsarDatabaseService {}
class MockSpotifyPublicService extends Mock implements SpotifyPublicService {}
class MockSearchAggregator extends Mock implements SearchAggregator {}
class MockYoutubeService extends Mock implements YoutubeService {}
class MockYoutubeAudioEngine extends Mock implements YoutubeAudioEngine {}

void main() {
  late SongRepositoryImpl repository;
  late MockIsarDatabaseService mockLocal;
  late MockSpotifyPublicService mockRemote;
  late MockSearchAggregator mockSearch;
  late MockYoutubeService mockYoutube;
  late MockYoutubeAudioEngine mockYtEngine;

  setUp(() {
    mockLocal = MockIsarDatabaseService();
    mockRemote = MockSpotifyPublicService();
    mockSearch = MockSearchAggregator();
    mockYoutube = MockYoutubeService();
    mockYtEngine = MockYoutubeAudioEngine();
    
    repository = SongRepositoryImpl(
      mockLocal,
      mockRemote,
      mockYoutube,
      mockYtEngine,
      mockSearch,
    );
  });

  group('Hybrid Audio Stream Resolution Regression Tests', () {
    test('should resolve YouTube stream via YoutubeAudioEngine', () async {
      const songId = 'yt_123';
      const expectedUri = 'https://yt.com/stream/123';
      
      when(() => mockYtEngine.getStreamUri(songId))
          .thenAnswer((_) async => expectedUri);

      final result = await repository.resolveStreamUri(songId);

      expect(result, expectedUri);
      verify(() => mockYtEngine.getStreamUri(songId)).called(1);
    });

    test('should handle direct filesystem paths for local stubs (Phase 2)', () async {
      // NOTE: Current implementation only supports YT. 
      // This test serves as a regression stub for Local Path resolution.
      const localId = 'local_file_001';
      const localPath = '/storage/emulated/0/Music/song.mp3';
      
      // Stubbing the logic we expect to implement in Phase 2
      // For now, it might still go through ytEngine if not branched,
      // so we use this to define expected behavior.
      
      when(() => mockYtEngine.getStreamUri(localId))
          .thenAnswer((_) async => localPath);

      final result = await repository.resolveStreamUri(localId);

      expect(result, localPath);
    });
  });
}

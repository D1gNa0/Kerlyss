import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kerlyss/data/datasources/remote/youtube_audio_engine.dart';
import 'package:kerlyss/data/datasources/remote/youtube_service.dart';

class MockYoutubeService extends Mock implements YoutubeService {}

void main() {
  late YoutubeAudioEngine engine;
  late MockYoutubeService mockService;

  setUp(() {
    mockService = MockYoutubeService();
    engine = YoutubeAudioEngine(mockService);
  });

  group('YoutubeAudioEngine Caching Tests', () {
    const videoId = 'test_video_123';
    const streamUri = 'https://yt.com/stream/123';

    test('should fetch and cache URI on first call', () async {
      when(() => mockService.getStreamUri(videoId))
          .thenAnswer((_) async => streamUri);

      final result = await engine.getStreamUri(videoId);

      expect(result, streamUri);
      verify(() => mockService.getStreamUri(videoId)).called(1);
    });

    test('should return cached URI on second call without calling service', () async {
      when(() => mockService.getStreamUri(videoId))
          .thenAnswer((_) async => streamUri);

      // First call
      await engine.getStreamUri(videoId);
      // Second call
      final result = await engine.getStreamUri(videoId);

      expect(result, streamUri);
      verify(() => mockService.getStreamUri(videoId)).called(1);
    });

    test('should prevent redundant simultaneous calls (Concurrency Lock)', () async {
      final completer = Completer<String>();
      when(() => mockService.getStreamUri(videoId))
          .thenAnswer((_) => completer.future);

      // Trigger two simultaneous calls
      final call1 = engine.getStreamUri(videoId);
      final call2 = engine.getStreamUri(videoId);

      // Complete with some delay to ensure calls are pending
      await Future.delayed(Duration(milliseconds: 50));
      completer.complete(streamUri);

      final results = await Future.wait([call1, call2]);

      expect(results[0], streamUri);
      expect(results[1], streamUri);
      // Verify service only called once despite two parallel requests
      verify(() => mockService.getStreamUri(videoId)).called(1);
    });
  });
}

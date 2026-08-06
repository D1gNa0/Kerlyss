import 'dart:collection';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:kerlyss/core/services/youtube_proxy_server.dart';
import 'package:kerlyss/core/services/stream_resolution_cache.dart';

class MockYoutubeExplode extends Mock implements YoutubeExplode {}
class MockVideoClient extends Mock implements VideoClient {}
class MockStreamClient extends Mock implements StreamClient {}
class MockStreamManifest extends Mock implements StreamManifest {}
class MockAudioOnlyStreamInfo extends Mock implements AudioOnlyStreamInfo {}

void main() {
  group('YoutubeProxyServer.getStreamInfoForSong Tests', () {
    late MockYoutubeExplode mockYt;
    late MockVideoClient mockVideos;
    late MockStreamClient mockStreams;
    late MockStreamManifest mockManifest;
    late MockAudioOnlyStreamInfo mockStreamInfo;

    setUp(() {
      mockYt = MockYoutubeExplode();
      mockVideos = MockVideoClient();
      mockStreams = MockStreamClient();
      mockManifest = MockStreamManifest();
      mockStreamInfo = MockAudioOnlyStreamInfo();

      when(() => mockYt.videos).thenReturn(mockVideos);
      when(() => mockVideos.streamsClient).thenReturn(mockStreams);

      // Clean caches before each test
      YoutubeProxyServer.clearCaches();
      StreamResolutionCache.instance.clear();
    });

    test('should return null when song/video is not cached', () {
      final result = YoutubeProxyServer.getStreamInfoForSong('non_existent');
      expect(result, isNull);
    });

    test('should return cached stream info when queried with videoId', () async {
      const videoId = 'video_123';

      when(() => mockStreams.getManifest(
            any(),
            ytClients: any(named: 'ytClients'),
          )).thenAnswer((_) async => mockManifest);
      
      when(() => mockManifest.audioOnly).thenReturn(UnmodifiableListView<AudioOnlyStreamInfo>([mockStreamInfo]));
      when(() => mockStreamInfo.bitrate).thenReturn(const Bitrate(128000));

      // Prefetch to populate cache
      await YoutubeProxyServer.prefetchStream(videoId, mockYt);

      // Retrieve cached info using videoId
      final retrieved = YoutubeProxyServer.getStreamInfoForSong(videoId);
      expect(retrieved, equals(mockStreamInfo));
    });

    test('should return cached stream info when queried with songId mapped in StreamResolutionCache', () async {
      const songId = 'song_deezer_456';
      const videoId = 'video_456';

      // Setup cache resolution
      StreamResolutionCache.instance.put(songId, videoId);

      when(() => mockStreams.getManifest(
            any(),
            ytClients: any(named: 'ytClients'),
          )).thenAnswer((_) async => mockManifest);
      
      when(() => mockManifest.audioOnly).thenReturn(UnmodifiableListView<AudioOnlyStreamInfo>([mockStreamInfo]));
      when(() => mockStreamInfo.bitrate).thenReturn(const Bitrate(128000));

      // Prefetch video stream
      await YoutubeProxyServer.prefetchStream(videoId, mockYt);

      // Retrieve cached info using songId
      final retrieved = YoutubeProxyServer.getStreamInfoForSong(songId);
      expect(retrieved, equals(mockStreamInfo));
    });
  });
}

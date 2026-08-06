import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

import 'package:kerlyss/presentation/state/audio_provider.dart';
import 'package:kerlyss/presentation/state/audio_state.dart';
import 'package:kerlyss/domain/repositories/audio_service_interface.dart';
import 'package:kerlyss/domain/repositories/song_repository.dart';
import 'package:kerlyss/data/datasources/local/local_download_library.dart';
import 'package:kerlyss/data/datasources/local/isar_database_service.dart';
import 'package:kerlyss/data/datasources/remote/youtube_service.dart';
import 'package:kerlyss/domain/entities/audio_source_type.dart';
import 'package:kerlyss/domain/entities/song_entity.dart';
import 'package:kerlyss/core/services/youtube_proxy_server.dart';
import 'package:kerlyss/core/services/kerlyss_audio_handler.dart';
import 'package:kerlyss/main.dart' as main_app;

import 'package:just_audio/just_audio.dart';

class MockAudioService extends Mock implements AudioServiceInterface {}
class MockLocalDownloadLibrary extends Mock implements LocalDownloadLibrary {}
class MockYoutubeService extends Mock implements YoutubeService {}
class MockIsarDatabaseService extends Mock implements IsarDatabaseService {}
class MockSongRepository extends Mock implements SongRepository {}
class MockKerlyssAudioHandler extends Mock implements KerlyssAudioHandler {}
class MockAndroidEqualizer extends Mock implements AndroidEqualizer {}
class MockAndroidEqualizerParameters extends Mock implements AndroidEqualizerParameters {}
class MockAndroidEqualizerBand extends Mock implements AndroidEqualizerBand {}
class MockYoutubeExplode extends Mock implements yt.YoutubeExplode {}
class FakeAudioSource extends Fake implements AudioSource {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAudioService mockAudioService;
  late MockLocalDownloadLibrary mockLocalDownloadLibrary;
  late MockYoutubeService mockYoutubeService;
  late MockIsarDatabaseService mockIsarDatabaseService;
  late MockSongRepository mockSongRepository;
  
  late MockKerlyssAudioHandler mockAudioHandler;
  late MockAndroidEqualizer mockEqualizer;
  late MockAndroidEqualizerParameters mockEqualizerParams;
  late MockAndroidEqualizerBand mockEqualizerBand;

  final playbackStatusController = StreamController<PlaybackStatus>.broadcast();
  final currentIndexController = StreamController<int?>.broadcast();
  final positionController = StreamController<Duration>.broadcast();
  final durationController = StreamController<Duration?>.broadcast();
  final bufferedPositionController = StreamController<Duration>.broadcast();

  setUpAll(() {
    registerFallbackValue(SongMetadata.empty());
    registerFallbackValue(Duration.zero);
    registerFallbackValue(FakeAudioSource());
    registerFallbackValue(SongEntity(
      id: '',
      title: '',
      artist: '',
      album: '',
      duration: Duration.zero,
      sourceUrl: '',
      sourceType: AudioSourceType.local,
      dateAdded: DateTime.now(),
    ));
    
    mockAudioHandler = MockKerlyssAudioHandler();
    mockEqualizer = MockAndroidEqualizer();
    mockEqualizerParams = MockAndroidEqualizerParameters();
    mockEqualizerBand = MockAndroidEqualizerBand();

    try {
      main_app.globalAudioHandler;
    } catch (_) {
      main_app.globalAudioHandler = mockAudioHandler;
    }
  });

  setUp(() {
    mockAudioService = MockAudioService();
    mockLocalDownloadLibrary = MockLocalDownloadLibrary();
    mockYoutubeService = MockYoutubeService();
    mockIsarDatabaseService = MockIsarDatabaseService();
    mockSongRepository = MockSongRepository();

    // Stub stream properties on AudioServiceInterface
    when(() => mockAudioService.playbackStatusStream).thenAnswer((_) => playbackStatusController.stream);
    when(() => mockAudioService.currentIndexStream).thenAnswer((_) => currentIndexController.stream);
    when(() => mockAudioService.positionStream).thenAnswer((_) => positionController.stream);
    when(() => mockAudioService.durationStream).thenAnswer((_) => durationController.stream);
    when(() => mockAudioService.bufferedPositionStream).thenAnswer((_) => bufferedPositionController.stream);
    when(() => mockAudioService.setVolume(any())).thenAnswer((_) async => null);
    when(() => mockAudioService.playing).thenReturn(false);
    when(() => mockAudioService.position).thenReturn(Duration.zero);
    when(() => mockAudioService.duration).thenReturn(Duration.zero);
    when(() => mockAudioService.currentIndex).thenReturn(0);
    when(() => mockAudioService.queueLength).thenReturn(0);

    // Stub globalAudioHandler properties
    when(() => mockAudioHandler.setMediaFromSong(any())).thenReturn(null);
    when(() => mockAudioHandler.equalizer).thenReturn(mockEqualizer);

    // Stub AndroidEqualizer properties
    when(() => mockEqualizer.setEnabled(any())).thenAnswer((_) async => null);
    when(() => mockEqualizer.parameters).thenAnswer((_) async => mockEqualizerParams);
    when(() => mockEqualizerParams.bands).thenReturn([mockEqualizerBand]);
    when(() => mockEqualizerBand.setGain(any())).thenAnswer((_) async => null);

    // Stub isar database service
    when(() => mockIsarDatabaseService.getSongById(any())).thenAnswer((_) async => null);
    when(() => mockSongRepository.resolveStreamUri(any())).thenAnswer((_) async => '');
    
    final mockYt = MockYoutubeExplode();
    when(() => mockYoutubeService.client).thenReturn(mockYt);
  });

  group('AudioState & copyWith Tests', () {
    test('supports new audio properties and copyWith clearing flags', () {
      const state = AudioState(
        currentSong: SongMetadata(
          id: 'test_song',
          title: 'Test Title',
          artist: 'Test Artist',
          duration: Duration(minutes: 3),
        ),
        status: PlaybackStatus.ready,
        position: Duration.zero,
        bufferedPosition: Duration.zero,
      );

      expect(state.audioFormat, isNull);
      expect(state.audioBitrate, isNull);
      expect(state.audioSize, isNull);

      final withFormat = state.copyWith(
        audioFormat: 'MP3',
        audioBitrate: '320 kbps',
        audioSize: '6.5 MB',
      );

      expect(withFormat.audioFormat, equals('MP3'));
      expect(withFormat.audioBitrate, equals('320 kbps'));
      expect(withFormat.audioSize, equals('6.5 MB'));

      final clearedFormat = withFormat.copyWith(
        clearAudioFormat: true,
      );
      expect(clearedFormat.audioFormat, isNull);
      expect(clearedFormat.audioBitrate, equals('320 kbps'));

      final clearedAll = withFormat.copyWith(
        clearAudioFormat: true,
        clearAudioBitrate: true,
        clearAudioSize: true,
      );
      expect(clearedAll.audioFormat, isNull);
      expect(clearedAll.audioBitrate, isNull);
      expect(clearedAll.audioSize, isNull);
    });
  });

  group('AudioNotifier Tests', () {
    test('sets equalizer preset and applies band gains asynchronously', () async {
      final notifier = AudioNotifier(
        mockLocalDownloadLibrary,
        mockYoutubeService,
        mockAudioService,
        mockIsarDatabaseService,
        mockSongRepository,
      );

      notifier.setEqPreset('Bass Boost');
      
      expect(notifier.state.eqPreset, equals('Bass Boost'));
      
      // Wait for async task to run
      await Future.delayed(Duration.zero);
      
      verify(() => mockEqualizer.setEnabled(true)).called(1);
      verify(() => mockEqualizerBand.setGain(5.0)).called(1);
    });

    test('updates audio details for a local file', () async {
      final tempFile = File('${Directory.systemTemp.path}/test_song.mp3');
      await tempFile.writeAsBytes(List.generate(1024 * 1024 * 5, (index) => 0)); // 5 MB file

      final notifier = AudioNotifier(
        mockLocalDownloadLibrary,
        mockYoutubeService,
        mockAudioService,
        mockIsarDatabaseService,
        mockSongRepository,
      );

      final song = SongMetadata(
        id: tempFile.path,
        title: 'Local Test Song',
        artist: 'Local Artist',
        duration: const Duration(seconds: 200),
        source: AudioSourceType.local,
      );

      when(() => mockAudioService.setAudioQueue(any(), initialIndex: any(named: 'initialIndex'), play: any(named: 'play'))).thenAnswer((_) async => null);
      when(() => mockAudioService.play()).thenAnswer((_) async => null);

      await notifier.playPlaylist([song], 0);

      expect(notifier.state.audioFormat, equals('MP3'));
      expect(notifier.state.audioSize, equals('5.0 MB'));
      expect(notifier.state.audioBitrate, equals('210 kbps'));

      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    });

    test('updates audio details for a remote stream (uncached default fallback)', () async {
      final notifier = AudioNotifier(
        mockLocalDownloadLibrary,
        mockYoutubeService,
        mockAudioService,
        mockIsarDatabaseService,
        mockSongRepository,
      );

      final song = SongMetadata(
        id: 'remote_youtube_123',
        title: 'Remote Test Song',
        artist: 'Remote Artist',
        duration: const Duration(seconds: 200),
        source: AudioSourceType.youtube,
      );

      when(() => mockAudioService.setAudioQueue(any(), initialIndex: any(named: 'initialIndex'), play: any(named: 'play'))).thenAnswer((_) async => null);
      when(() => mockAudioService.play()).thenAnswer((_) async => null);

      await notifier.playPlaylist([song], 0);
      
      await Future.delayed(const Duration(milliseconds: 1100));

      expect(notifier.state.audioFormat, equals('AAC/OPUS'));
      expect(notifier.state.audioBitrate, equals('160 kbps (Est)'));
      expect(notifier.state.audioSize, equals('Streaming'));
    });
  });
}

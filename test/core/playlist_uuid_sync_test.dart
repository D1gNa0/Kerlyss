import 'package:flutter_test/flutter_test.dart';
import 'package:kerlyss/core/services/google_drive_sync_service.dart';
import 'package:kerlyss/core/utils/uuid_generator.dart';
import 'package:kerlyss/data/datasources/local/isar_database_service.dart';
import 'package:kerlyss/data/models/playlist_model.dart';
import 'package:kerlyss/data/models/song_model.dart';
import 'package:kerlyss/data/models/app_settings_model.dart';
import 'package:mocktail/mocktail.dart';

class MockIsarDatabaseService extends Mock implements IsarDatabaseService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(PlaylistModel());
    registerFallbackValue(SongModel());
    registerFallbackValue(AppSettingsModel());
  });

  group('Playlist UUID and Cloud Sync Tests', () {
    test('UuidGenerator produces valid RFC 4122 v4 UUID format', () {
      final uuid1 = UuidGenerator.generate();
      final uuid2 = UuidGenerator.generate();

      expect(uuid1, isNotEmpty);
      expect(uuid2, isNotEmpty);
      expect(uuid1, isNot(equals(uuid2)));

      final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
      expect(uuidRegex.hasMatch(uuid1), isTrue);
      expect(uuidRegex.hasMatch(uuid2), isTrue);
    });

    test('Playlist renaming preserves UUID and updates existing record without duplicate', () async {
      final mockIsar = MockIsarDatabaseService();

      final existingLocal = PlaylistModel()
        ..id = 1
        ..uuid = 'playlist-uuid-abc'
        ..name = 'Original Name'
        ..songIds = ['song1', 'song2']
        ..createdAt = DateTime(2026, 1, 1)
        ..lastSyncedAt = DateTime(2026, 1, 1);

      final localPlaylists = [existingLocal];
      final savedPlaylists = <PlaylistModel>[];

      when(() => mockIsar.getAllPlaylists()).thenAnswer((_) async => localPlaylists);
      when(() => mockIsar.savePlaylist(any())).thenAnswer((inv) async {
        final p = inv.positionalArguments[0] as PlaylistModel;
        savedPlaylists.add(p);
      });
      when(() => mockIsar.getAllSongs()).thenAnswer((_) async => []);
      when(() => mockIsar.getSettings()).thenAnswer((_) async => AppSettingsModel());

      final service = GoogleDriveSyncService(mockIsar);

      // Simulate remote data where playlist-uuid-abc was renamed to "Renamed by Device B" with newer timestamp
      final newerTime = DateTime(2026, 2, 1);
      final remoteJson = {
        'version': 1,
        'playlists': [
          {
            'uuid': 'playlist-uuid-abc',
            'name': 'Renamed by Device B',
            'songIds': ['song1', 'song2', 'song3'],
            'createdAt': DateTime(2026, 1, 1).toIso8601String(),
            'lastSyncedAt': newerTime.toIso8601String(),
            'isRealtimeSynced': false,
            'autoDownloadNewTracks': false,
          }
        ],
        'songs': [],
        'dislikedSongIds': [],
        'dislikedArtists': [],
      };

      await service.mergeRemoteDataForTesting(remoteJson);

      // Assert:
      // 1. Exactly 1 playlist was saved (the existing local playlist updated)
      expect(savedPlaylists.length, equals(1));
      // 2. The existing playlist's ID and UUID are preserved
      expect(savedPlaylists.first.id, equals(1));
      expect(savedPlaylists.first.uuid, equals('playlist-uuid-abc'));
      // 3. The name is updated to the renamed version
      expect(savedPlaylists.first.name, equals('Renamed by Device B'));
      // 4. Songs and timestamp were updated
      expect(savedPlaylists.first.songIds, equals(['song1', 'song2', 'song3']));
      expect(savedPlaylists.first.lastSyncedAt, equals(newerTime));
    });

    test('New remote playlist with distinct UUID creates new local playlist', () async {
      final mockIsar = MockIsarDatabaseService();

      final existingLocal = PlaylistModel()
        ..id = 1
        ..uuid = 'playlist-uuid-abc'
        ..name = 'My First Playlist'
        ..songIds = ['song1']
        ..createdAt = DateTime(2026, 1, 1)
        ..lastSyncedAt = DateTime(2026, 1, 1);

      final localPlaylists = [existingLocal];
      final savedPlaylists = <PlaylistModel>[];

      when(() => mockIsar.getAllPlaylists()).thenAnswer((_) async => localPlaylists);
      when(() => mockIsar.savePlaylist(any())).thenAnswer((inv) async {
        final p = inv.positionalArguments[0] as PlaylistModel;
        savedPlaylists.add(p);
      });
      when(() => mockIsar.getAllSongs()).thenAnswer((_) async => []);
      when(() => mockIsar.getSettings()).thenAnswer((_) async => AppSettingsModel());

      final service = GoogleDriveSyncService(mockIsar);

      final remoteJson = {
        'version': 1,
        'playlists': [
          {
            'uuid': 'playlist-uuid-xyz',
            'name': 'Brand New Playlist',
            'songIds': ['song99'],
            'createdAt': DateTime(2026, 2, 1).toIso8601String(),
            'lastSyncedAt': DateTime(2026, 2, 1).toIso8601String(),
            'isRealtimeSynced': false,
            'autoDownloadNewTracks': false,
          }
        ],
        'songs': [],
        'dislikedSongIds': [],
        'dislikedArtists': [],
      };

      await service.mergeRemoteDataForTesting(remoteJson);

      expect(savedPlaylists.length, equals(1));
      expect(savedPlaylists.first.uuid, equals('playlist-uuid-xyz'));
      expect(savedPlaylists.first.name, equals('Brand New Playlist'));
      expect(savedPlaylists.first.songIds, equals(['song99']));
    });
  });
}

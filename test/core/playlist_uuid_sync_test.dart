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
      when(() => mockIsar.purgeOldDeletedPlaylists()).thenAnswer((_) async {});

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
      when(() => mockIsar.purgeOldDeletedPlaylists()).thenAnswer((_) async {});

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

    test('Song removal on remote device propagates to local device without union resurrection', () async {
      final mockIsar = MockIsarDatabaseService();

      final existingLocal = PlaylistModel()
        ..id = 2
        ..uuid = 'playlist-uuid-removal'
        ..name = 'My Songs'
        ..songIds = ['song1', 'song2', 'song3']
        ..createdAt = DateTime(2026, 1, 1)
        ..updatedAt = DateTime(2026, 1, 1)
        ..lastSyncedAt = DateTime(2026, 1, 1);

      final localPlaylists = [existingLocal];
      final savedPlaylists = <PlaylistModel>[];

      when(() => mockIsar.getAllPlaylistsIncludingDeleted()).thenAnswer((_) async => localPlaylists);
      when(() => mockIsar.getAllPlaylists()).thenAnswer((_) async => localPlaylists);
      when(() => mockIsar.savePlaylist(any())).thenAnswer((inv) async {
        final p = inv.positionalArguments[0] as PlaylistModel;
        savedPlaylists.add(p);
      });
      when(() => mockIsar.getAllSongs()).thenAnswer((_) async => []);
      when(() => mockIsar.getSettings()).thenAnswer((_) async => AppSettingsModel());
      when(() => mockIsar.purgeOldDeletedPlaylists()).thenAnswer((_) async {});

      final service = GoogleDriveSyncService(mockIsar);

      // Remote removed 'song3' at a later timestamp (2026-02-01)
      final newerTime = DateTime(2026, 2, 1);
      final remoteJson = {
        'version': 1,
        'playlists': [
          {
            'uuid': 'playlist-uuid-removal',
            'name': 'My Songs',
            'songIds': ['song1', 'song2'], // song3 removed
            'createdAt': DateTime(2026, 1, 1).toIso8601String(),
            'updatedAt': newerTime.toIso8601String(),
            'lastSyncedAt': newerTime.toIso8601String(),
            'isDeleted': false,
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
      // Exactly 2 songs remain; song3 is cleanly removed without resurrection
      expect(savedPlaylists.first.songIds, equals(['song1', 'song2']));
      expect(savedPlaylists.first.songIds.contains('song3'), isFalse);
      expect(savedPlaylists.first.updatedAt, equals(newerTime));
    });

    test('Newer local edits win over older remote edits (LWW local wins)', () async {
      final mockIsar = MockIsarDatabaseService();

      final localNewerTime = DateTime(2026, 3, 1);
      final existingLocal = PlaylistModel()
        ..id = 3
        ..uuid = 'playlist-uuid-lww'
        ..name = 'Local Newer Name'
        ..songIds = ['song1', 'song2', 'song3', 'song4']
        ..createdAt = DateTime(2026, 1, 1)
        ..updatedAt = localNewerTime
        ..lastSyncedAt = DateTime(2026, 2, 1);

      final localPlaylists = [existingLocal];
      final savedPlaylists = <PlaylistModel>[];

      when(() => mockIsar.getAllPlaylistsIncludingDeleted()).thenAnswer((_) async => localPlaylists);
      when(() => mockIsar.getAllPlaylists()).thenAnswer((_) async => localPlaylists);
      when(() => mockIsar.savePlaylist(any())).thenAnswer((inv) async {
        final p = inv.positionalArguments[0] as PlaylistModel;
        savedPlaylists.add(p);
      });
      when(() => mockIsar.getAllSongs()).thenAnswer((_) async => []);
      when(() => mockIsar.getSettings()).thenAnswer((_) async => AppSettingsModel());
      when(() => mockIsar.purgeOldDeletedPlaylists()).thenAnswer((_) async {});

      final service = GoogleDriveSyncService(mockIsar);

      // Remote has older edit from 2026-02-15
      final remoteOlderTime = DateTime(2026, 2, 15);
      final remoteJson = {
        'version': 1,
        'playlists': [
          {
            'uuid': 'playlist-uuid-lww',
            'name': 'Remote Stale Name',
            'songIds': ['song1'],
            'createdAt': DateTime(2026, 1, 1).toIso8601String(),
            'updatedAt': remoteOlderTime.toIso8601String(),
            'isDeleted': false,
            'isRealtimeSynced': false,
            'autoDownloadNewTracks': false,
          }
        ],
        'songs': [],
        'dislikedSongIds': [],
        'dislikedArtists': [],
      };

      await service.mergeRemoteDataForTesting(remoteJson);

      // Local was strictly newer (March vs Feb): local state preserved, no overwrite saved
      expect(savedPlaylists.isEmpty, isTrue);
      expect(existingLocal.name, equals('Local Newer Name'));
      expect(existingLocal.songIds.length, equals(4));
    });

    test('Remote tombstone (isDeleted == true) soft-deletes local playlist', () async {
      final mockIsar = MockIsarDatabaseService();

      final existingLocal = PlaylistModel()
        ..id = 4
        ..uuid = 'playlist-uuid-tombstone'
        ..name = 'Playlist to Delete'
        ..songIds = ['s1', 's2']
        ..createdAt = DateTime(2026, 1, 1)
        ..updatedAt = DateTime(2026, 1, 1)
        ..isDeleted = false;

      final localPlaylists = [existingLocal];
      final savedPlaylists = <PlaylistModel>[];

      when(() => mockIsar.getAllPlaylistsIncludingDeleted()).thenAnswer((_) async => localPlaylists);
      when(() => mockIsar.getAllPlaylists()).thenAnswer((_) async => localPlaylists);
      when(() => mockIsar.savePlaylist(any())).thenAnswer((inv) async {
        final p = inv.positionalArguments[0] as PlaylistModel;
        savedPlaylists.add(p);
      });
      when(() => mockIsar.getAllSongs()).thenAnswer((_) async => []);
      when(() => mockIsar.getSettings()).thenAnswer((_) async => AppSettingsModel());
      when(() => mockIsar.purgeOldDeletedPlaylists()).thenAnswer((_) async {});

      final service = GoogleDriveSyncService(mockIsar);

      final deleteTime = DateTime(2026, 2, 1);
      final remoteJson = {
        'version': 1,
        'playlists': [
          {
            'uuid': 'playlist-uuid-tombstone',
            'name': 'Playlist to Delete',
            'songIds': ['s1', 's2'],
            'createdAt': DateTime(2026, 1, 1).toIso8601String(),
            'updatedAt': deleteTime.toIso8601String(),
            'isDeleted': true,
            'deletedAt': deleteTime.toIso8601String(),
          }
        ],
        'songs': [],
        'dislikedSongIds': [],
        'dislikedArtists': [],
      };

      await service.mergeRemoteDataForTesting(remoteJson);

      expect(savedPlaylists.length, equals(1));
      expect(savedPlaylists.first.isDeleted, isTrue);
      expect(savedPlaylists.first.deletedAt, equals(deleteTime));
      expect(savedPlaylists.first.updatedAt, equals(deleteTime));
    });

    test('Local tombstone exports isDeleted: true and deletedAt', () async {
      final mockIsar = MockIsarDatabaseService();

      final deletedPlaylist = PlaylistModel()
        ..id = 5
        ..uuid = 'playlist-uuid-exported-tombstone'
        ..name = 'Deleted Local Playlist'
        ..songIds = []
        ..createdAt = DateTime(2026, 1, 1)
        ..updatedAt = DateTime(2026, 2, 1)
        ..isDeleted = true
        ..deletedAt = DateTime(2026, 2, 1);

      when(() => mockIsar.getAllPlaylistsIncludingDeleted()).thenAnswer((_) async => [deletedPlaylist]);
      when(() => mockIsar.getAllPlaylists()).thenAnswer((_) async => []);
      when(() => mockIsar.getAllSongs()).thenAnswer((_) async => []);
      when(() => mockIsar.getSettings()).thenAnswer((_) async => AppSettingsModel());

      final service = GoogleDriveSyncService(mockIsar);
      final exported = await service.exportLocalDataForTesting();

      final playlistsJson = exported['playlists'] as List;
      expect(playlistsJson.length, equals(1));
      final exportedPlaylist = playlistsJson.first as Map<String, dynamic>;
      expect(exportedPlaylist['uuid'], equals('playlist-uuid-exported-tombstone'));
      expect(exportedPlaylist['isDeleted'], isTrue);
      expect(exportedPlaylist['deletedAt'], equals(DateTime(2026, 2, 1).toIso8601String()));
      expect(exportedPlaylist['updatedAt'], equals(DateTime(2026, 2, 1).toIso8601String()));
    });

    test('mergeRemoteData handles integer timestamp lastModified and mixed types without error', () async {
      final mockIsar = MockIsarDatabaseService();
      when(() => mockIsar.getAllPlaylistsIncludingDeleted()).thenAnswer((_) async => []);
      when(() => mockIsar.getAllPlaylists()).thenAnswer((_) async => []);
      when(() => mockIsar.getAllSongs()).thenAnswer((_) async => []);
      when(() => mockIsar.getSongById(any())).thenAnswer((_) async => null);
      when(() => mockIsar.saveSong(any())).thenAnswer((_) async => 1);
      when(() => mockIsar.savePlaylist(any())).thenAnswer((_) async => 1);
      when(() => mockIsar.getSettings()).thenAnswer((_) async => AppSettingsModel());
      when(() => mockIsar.saveSettings(any())).thenAnswer((_) async => 1);
      when(() => mockIsar.purgeOldDeletedPlaylists()).thenAnswer((_) async {});

      final service = GoogleDriveSyncService(mockIsar);

      // Payload where lastModified is an integer (epoch milliseconds)
      final remoteJson = {
        'version': 1,
        'lastModified': 1727860000000,
        'playlists': [
          {
            'uuid': 'uuid-int-test',
            'name': 'Int Timestamp Playlist',
            'songIds': ['song_1', 'song_2'],
            'createdAt': 1727850000000,
            'updatedAt': 1727860000000,
            'isRealtimeSynced': false,
            'autoDownloadNewTracks': false,
          }
        ],
        'songs': [
          {
            'songId': 'song_1',
            'title': 'Test Song',
            'artist': 'Artist',
            'durationMs': 180000,
            'bpm': 120,
            'dateAdded': 1727850000000,
          }
        ],
        'dislikedSongIds': ['disliked_1'],
        'dislikedArtists': ['disliked_artist_1'],
      };

      // Should complete cleanly without throwing type cast error
      await expectLater(service.mergeRemoteDataForTesting(remoteJson), completes);
    });
  });
}

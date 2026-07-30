import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:kerlyss/data/models/playlist_model.dart';
import 'package:kerlyss/domain/entities/playlist_entity.dart';

void main() {
  group('PlaylistModel Mapping Tests', () {
    test('Mapping from PlaylistModel to PlaylistEntity preserves all fields', () {
      final now = DateTime.now();
      final model = PlaylistModel()
        ..id = 42
        ..name = 'My Awesome Playlist'
        ..songIds = ['song_1', 'song_2']
        ..createdAt = now;

      final entity = model.toEntity();

      expect(entity.id, equals(42));
      expect(entity.name, equals('My Awesome Playlist'));
      expect(entity.songIds, equals(['song_1', 'song_2']));
      expect(entity.createdAt, equals(now));
    });

    test('Mapping from PlaylistEntity to PlaylistModel preserves all fields', () {
      final now = DateTime.now();
      final entity = PlaylistEntity(
        id: 99,
        name: 'Another Playlist',
        songIds: ['song_3'],
        createdAt: now,
      );

      final model = PlaylistModel.fromEntity(entity);

      expect(model.id, equals(99));
      expect(model.name, equals('Another Playlist'));
      expect(model.songIds, equals(['song_3']));
      expect(model.createdAt, equals(now));
    });

    test('Mapping PlaylistEntity to PlaylistModel handles null id (autoIncrement)', () {
      final now = DateTime.now();
      final entity = PlaylistEntity(
        id: null,
        name: 'New Playlist',
        songIds: [],
        createdAt: now,
      );

      final model = PlaylistModel.fromEntity(entity);

      // In Isar, a null id maps to the default/initial autoIncrement placeholder value
      expect(model.id, equals(Isar.autoIncrement));
      expect(model.name, equals('New Playlist'));
      expect(model.songIds, isEmpty);
      expect(model.createdAt, equals(now));
    });

    test('Mapping from PlaylistModel to PlaylistEntity preserves real-time sync fields', () {
      final now = DateTime.now();
      final model = PlaylistModel()
        ..id = 42
        ..name = 'My Synced Playlist'
        ..songIds = ['song_1']
        ..createdAt = now
        ..isRealtimeSynced = true
        ..autoDownloadNewTracks = true
        ..spotifySourceUrl = 'https://spotify.com/playlist/123'
        ..coverArtUrl = 'https://example.com/cover.jpg'
        ..lastSyncedAt = now;

      final entity = model.toEntity();

      expect(entity.id, equals(42));
      expect(entity.name, equals('My Synced Playlist'));
      expect(entity.songIds, equals(['song_1']));
      expect(entity.createdAt, equals(now));
      expect(entity.isRealtimeSynced, isTrue);
      expect(entity.autoDownloadNewTracks, isTrue);
      expect(entity.spotifySourceUrl, equals('https://spotify.com/playlist/123'));
      expect(entity.coverArtUrl, equals('https://example.com/cover.jpg'));
      expect(entity.lastSyncedAt, equals(now));
    });

    test('Mapping from PlaylistEntity to PlaylistModel preserves real-time sync fields', () {
      final now = DateTime.now();
      final entity = PlaylistEntity(
        id: 99,
        name: 'Another Synced Playlist',
        songIds: ['song_3'],
        createdAt: now,
        isRealtimeSynced: true,
        autoDownloadNewTracks: true,
        spotifySourceUrl: 'https://spotify.com/playlist/456',
        coverArtUrl: 'https://example.com/cover2.jpg',
        lastSyncedAt: now,
      );

      final model = PlaylistModel.fromEntity(entity);

      expect(model.id, equals(99));
      expect(model.name, equals('Another Synced Playlist'));
      expect(model.songIds, equals(['song_3']));
      expect(model.createdAt, equals(now));
      expect(model.isRealtimeSynced, isTrue);
      expect(model.autoDownloadNewTracks, isTrue);
      expect(model.spotifySourceUrl, equals('https://spotify.com/playlist/456'));
      expect(model.coverArtUrl, equals('https://example.com/cover2.jpg'));
      expect(model.lastSyncedAt, equals(now));
    });

    test('Mapping default real-time sync values', () {
      final now = DateTime.now();
      final entity = PlaylistEntity(
        id: 1,
        name: 'Default Playlist',
        songIds: [],
        createdAt: now,
      );

      final model = PlaylistModel.fromEntity(entity);

      expect(model.isRealtimeSynced, isFalse);
      expect(model.autoDownloadNewTracks, isFalse);
      expect(model.spotifySourceUrl, isNull);
      expect(model.coverArtUrl, isNull);
      expect(model.lastSyncedAt, isNull);

      final mappedEntity = model.toEntity();
      expect(mappedEntity.isRealtimeSynced, isFalse);
      expect(mappedEntity.autoDownloadNewTracks, isFalse);
      expect(mappedEntity.spotifySourceUrl, isNull);
      expect(mappedEntity.coverArtUrl, isNull);
      expect(mappedEntity.lastSyncedAt, isNull);
    });
  });
}

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
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:kerlyss/domain/entities/audio_source_type.dart';
import 'package:kerlyss/domain/entities/song_entity.dart';
import 'package:kerlyss/presentation/common/aether_song_tile.dart';

SongEntity song(String id, String title, String artist) => SongEntity(
      id: id,
      title: title,
      artist: artist,
      album: 'Album',
      duration: const Duration(seconds: 180),
      sourceType: AudioSourceType.youtube,
      sourceUrl: 'https://youtube.com/watch?v=$id',
      dateAdded: DateTime(2026, 1, 1),
    );

bool same(String id, String title, String artist, SongEntity row) => AetherSongTile.isSameTrack(
      currentId: id,
      currentTitle: title,
      currentArtist: artist,
      song: row,
    );

void main() {
  group('AetherSongTile.isSameTrack', () {
    test('same id is always the same track', () {
      expect(same('a', 'Intro', 'Band', song('a', 'Other title', 'Other')), isTrue);
    });

    test('same title but a different artist is NOT the same track', () {
      expect(same('a', 'Intro', 'Band One', song('b', 'Intro', 'Band Two')), isFalse);
    });

    test('same title and artist from another source is the same track', () {
      expect(same('yt1', ' Intro ', 'BAND', song('deezer9', 'intro', 'Band')), isTrue);
    });

    test('nothing playing matches nothing', () {
      expect(same('', 'Intro', 'Band', song('b', 'Intro', 'Band')), isFalse);
    });

    test('missing title or artist never matches by text', () {
      expect(same('a', '', 'Band', song('b', '', 'Band')), isFalse);
      expect(same('a', 'Intro', '', song('b', 'Intro', '')), isFalse);
    });
  });
}

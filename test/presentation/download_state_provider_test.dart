import 'package:flutter_test/flutter_test.dart';
import 'package:kerlyss/domain/entities/audio_source_type.dart';
import 'package:kerlyss/domain/entities/song_entity.dart';
import 'package:kerlyss/presentation/state/download_state_provider.dart';

void main() {
  group('DownloadStateNotifier Tests', () {
    late DownloadStateNotifier notifier;

    final testSong1 = SongEntity(
      id: 'song_1',
      title: 'First Song',
      artist: 'Artist 1',
      album: 'Album 1',
      duration: const Duration(seconds: 180),
      sourceType: AudioSourceType.youtube,
      sourceUrl: 'https://youtube.com/watch?v=song1',
      dateAdded: DateTime(2026, 1, 1),
    );

    final testSong2 = SongEntity(
      id: 'song_2',
      title: 'Second Song',
      artist: 'Artist 2',
      album: 'Album 2',
      duration: const Duration(seconds: 200),
      sourceType: AudioSourceType.youtube,
      sourceUrl: 'https://youtube.com/watch?v=song2',
      dateAdded: DateTime(2026, 1, 1),
    );

    setUp(() {
      notifier = DownloadStateNotifier();
    });

    tearDown(() {
      notifier.dispose();
    });

    test('setDownloadingSong adds song to activeDownloadSongs and downloadQueueOrder', () {
      notifier.setDownloadingSong(testSong1);

      final state = notifier.debugState;
      expect(state.downloadingTrackIds.contains('song_1'), isTrue);
      expect(state.activeDownloadSongs['song_1']?.title, equals('First Song'));
      expect(state.downloadQueueOrder, equals(['song_1']));
      expect(state.isAnyDownloadActive, isTrue);
      expect(state.activeSong?.id, equals('song_1'));
    });

    test('completeDownload clears active download and updates alreadyDownloadedIds', () {
      notifier.setDownloadingSong(testSong1);
      notifier.setDownloadingSong(testSong2);

      expect(notifier.debugState.downloadQueueOrder, equals(['song_1', 'song_2']));

      notifier.completeDownload('song_1');

      final state = notifier.debugState;
      expect(state.downloadingTrackIds.contains('song_1'), isFalse);
      expect(state.alreadyDownloadedIds.contains('song_1'), isTrue);
      expect(state.downloadQueueOrder, equals(['song_2']));
      expect(state.activeSong?.id, equals('song_2'));
    });

    test('clearDownloadAttempt removes song from active state without adding to downloaded', () {
      notifier.setDownloadingSong(testSong1);
      notifier.clearDownloadAttempt('song_1');

      final state = notifier.debugState;
      expect(state.downloadingTrackIds.contains('song_1'), isFalse);
      expect(state.alreadyDownloadedIds.contains('song_1'), isFalse);
      expect(state.downloadQueueOrder, isEmpty);
      expect(state.isAnyDownloadActive, isFalse);
    });
  });
}

extension on DownloadStateNotifier {
  DownloadState get debugState => state;
}

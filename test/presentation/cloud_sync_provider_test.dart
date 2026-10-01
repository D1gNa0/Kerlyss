import 'package:flutter_test/flutter_test.dart';
import 'package:kerlyss/presentation/state/cloud_sync_provider.dart';

void main() {
  group('CloudSyncState sync status indicators', () {
    test('disconnected state returns false for pending and true for synced fallback', () {
      const state = CloudSyncState(isConnected: false);
      expect(state.isPlaylistPending('uuid-1'), isFalse);
      expect(state.isSongPending('song-1'), isFalse);
    });

    test('connected state accurately identifies pending and synced playlists and songs', () {
      const state = CloudSyncState(
        isConnected: true,
        pendingSyncPlaylistUuids: {'uuid-pending'},
        pendingSyncSongIds: {'song-pending'},
      );

      // Playlists
      expect(state.isPlaylistPending('uuid-pending'), isTrue);
      expect(state.isPlaylistSynced('uuid-pending'), isFalse);
      expect(state.isPlaylistPending('uuid-other'), isFalse);
      expect(state.isPlaylistSynced('uuid-other'), isTrue);

      // Songs
      expect(state.isSongPending('song-pending'), isTrue);
      expect(state.isSongSynced('song-pending'), isFalse);
      expect(state.isSongPending('song-other'), isFalse);
      expect(state.isSongSynced('song-other'), isTrue);
    });

    test('copyWith updates pending sets correctly', () {
      var state = const CloudSyncState(isConnected: true);
      expect(state.pendingSyncPlaylistUuids, isEmpty);
      expect(state.pendingSyncSongIds, isEmpty);

      state = state.copyWith(
        pendingSyncPlaylistUuids: {'uuid-1'},
        pendingSyncSongIds: {'song-1', 'song-2'},
      );

      expect(state.pendingSyncPlaylistUuids, contains('uuid-1'));
      expect(state.pendingSyncSongIds, contains('song-1'));
      expect(state.pendingSyncSongIds, contains('song-2'));
      expect(state.isPlaylistPending('uuid-1'), isTrue);
      expect(state.isSongPending('song-1'), isTrue);
    });
  });
}

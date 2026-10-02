import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/google_drive_sync_service.dart';
import '../../core/services/logger_service.dart';
import '../../data/repositories/repository_providers.dart';
import 'app_settings_provider.dart';
import 'playlist_provider.dart';
import 'track_download_provider.dart';

class CloudSyncState {
  final bool isConnected;
  final bool isSyncing;
  final String? userEmail;
  final DateTime? lastSyncedAt;
  final String? errorMessage;
  final Set<String> pendingSyncPlaylistUuids;
  final Set<String> pendingSyncSongIds;

  const CloudSyncState({
    this.isConnected = false,
    this.isSyncing = false,
    this.userEmail,
    this.lastSyncedAt,
    this.errorMessage,
    this.pendingSyncPlaylistUuids = const {},
    this.pendingSyncSongIds = const {},
  });

  bool isPlaylistPending(String? uuid) =>
      isConnected && uuid != null && pendingSyncPlaylistUuids.contains(uuid);

  bool isPlaylistSynced(String? uuid) =>
      isConnected && (uuid == null || !pendingSyncPlaylistUuids.contains(uuid));

  bool isSongPending(String songId) =>
      isConnected && pendingSyncSongIds.contains(songId);

  bool isSongSynced(String songId) =>
      isConnected && !pendingSyncSongIds.contains(songId);

  int get pendingCount =>
      pendingSyncPlaylistUuids.length + pendingSyncSongIds.length;

  bool get hasPendingChanges => isConnected && pendingCount > 0;

  CloudSyncState copyWith({
    bool? isConnected,
    bool? isSyncing,
    String? userEmail,
    bool clearUserEmail = false,
    DateTime? lastSyncedAt,
    String? errorMessage,
    bool clearErrorMessage = false,
    Set<String>? pendingSyncPlaylistUuids,
    Set<String>? pendingSyncSongIds,
  }) {
    return CloudSyncState(
      isConnected: isConnected ?? this.isConnected,
      isSyncing: isSyncing ?? this.isSyncing,
      userEmail: clearUserEmail ? null : (userEmail ?? this.userEmail),
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      pendingSyncPlaylistUuids: pendingSyncPlaylistUuids ?? this.pendingSyncPlaylistUuids,
      pendingSyncSongIds: pendingSyncSongIds ?? this.pendingSyncSongIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CloudSyncState &&
          runtimeType == other.runtimeType &&
          isConnected == other.isConnected &&
          isSyncing == other.isSyncing &&
          userEmail == other.userEmail &&
          lastSyncedAt == other.lastSyncedAt &&
          errorMessage == other.errorMessage &&
          pendingSyncPlaylistUuids.length == other.pendingSyncPlaylistUuids.length &&
          pendingSyncPlaylistUuids.containsAll(other.pendingSyncPlaylistUuids) &&
          pendingSyncSongIds.length == other.pendingSyncSongIds.length &&
          pendingSyncSongIds.containsAll(other.pendingSyncSongIds);

  @override
  int get hashCode =>
      isConnected.hashCode ^
      isSyncing.hashCode ^
      userEmail.hashCode ^
      lastSyncedAt.hashCode ^
      errorMessage.hashCode ^
      pendingSyncPlaylistUuids.length.hashCode ^
      pendingSyncSongIds.length.hashCode;
}

class CloudSyncNotifier extends StateNotifier<CloudSyncState> {
  final GoogleDriveSyncService _driveService;
  final AppSettingsNotifier _settingsNotifier;
  final Ref _ref;
  bool _hasAttemptedSilentSignIn = false;

  CloudSyncNotifier(this._driveService, this._settingsNotifier, this._ref)
      : super(const CloudSyncState()) {
    // Listen for settings to finish loading from Isar asynchronously.
    // This fixes the race condition where AppSettingsNotifier.loadSettings()
    // hasn't completed yet when CloudSyncNotifier is constructed.
    _ref.listen<AppSettingsState>(
      appSettingsProvider,
      (previous, next) {
        if (!_hasAttemptedSilentSignIn && next.cloudSyncEnabled) {
          _hasAttemptedSilentSignIn = true;
          state = state.copyWith(
            isConnected: true,
            userEmail: next.googleAccountEmail,
            lastSyncedAt: next.lastCloudSyncAt,
          );
          _initSilentSignIn();
        }
      },
      fireImmediately: true,
    );
  }

  Future<void> _initSilentSignIn() async {
    final success = await _driveService.silentSignIn();
    if (success) {
      state = state.copyWith(
        isConnected: true,
        userEmail: _driveService.userEmail ?? state.userEmail,
      );
      // Auto-pull changes on startup
      await syncNow();
    } else {
      // Silent sign-in failed (expired/missing token). Show disconnected UI
      // so the user can re-authenticate instead of seeing a broken "connected" state.
      Log.w('CloudSyncNotifier: Silent sign-in failed, resetting to disconnected.');
      state = state.copyWith(
        isConnected: false,
        errorMessage: 'Session expired. Please reconnect.',
      );
      // Ensure local playlists are still loaded even though cloud is disconnected
      _ref.read(playlistProvider.notifier).loadPlaylists();
    }
  }

  Future<bool> connect() async {
    state = state.copyWith(isSyncing: true, clearErrorMessage: true);
    _hasAttemptedSilentSignIn = true;
    try {
      final success = await _driveService.signIn();
      if (success) {
        final email = _driveService.userEmail;
        final refreshToken = _driveService.currentRefreshToken;
        
        // Reload settings to ensure fresh state, then persist credentials
        await _settingsNotifier.loadSettings();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await _settingsNotifier.setGoogleRefreshToken(refreshToken);
        }
        await _settingsNotifier.setCloudSyncEnabled(true);
        await _settingsNotifier.setGoogleAccountEmail(email);

        state = state.copyWith(
          isConnected: true,
          isSyncing: false,
          userEmail: email,
        );

        // Perform initial pull and merge
        await syncNow();
        return true;
      } else {
        state = state.copyWith(
          isSyncing: false,
          errorMessage: 'Sign-in was cancelled or failed.',
        );
        return false;
      }
    } catch (e) {
      Log.e('CloudSyncNotifier: Connect error: $e');
      state = state.copyWith(
        isSyncing: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void cancelConnect() {
    if (state.isSyncing) {
      state = state.copyWith(
        isSyncing: false,
        errorMessage: 'Sign-in cancelled.',
      );
    }
  }

  Future<void> disconnect() async {
    await _driveService.signOut();
    await _settingsNotifier.setCloudSyncEnabled(false);
    await _settingsNotifier.setGoogleAccountEmail(null);
    await _settingsNotifier.setGoogleRefreshToken(null);

    state = state.copyWith(
      isConnected: false,
      clearUserEmail: true,
      clearErrorMessage: true,
      pendingSyncPlaylistUuids: {},
      pendingSyncSongIds: {},
    );
  }

  Future<bool> syncNow() async {
    if (!state.isConnected) return false;
    state = state.copyWith(isSyncing: true, clearErrorMessage: true);

    try {
      final pullSuccess = await _driveService.pullAndMerge();
      if (pullSuccess) {
        // Trigger UI refresh so lists instantly update
        _ref.read(playlistProvider.notifier).loadPlaylists();
        _settingsNotifier.loadSettings();

        // Check if any songs need auto-downloading from remote playlist updates
        final autoDownloadIds = _driveService.consumeNewlyDiscoveredAutoDownloadSongIds();
        if (autoDownloadIds.isNotEmpty) {
          Log.i('CloudSyncNotifier: Found ${autoDownloadIds.length} new tracks to auto-download.');
          final songs = await _ref.read(songRepositoryProvider).getSongsByIds(autoDownloadIds);
          if (songs.isNotEmpty) {
            _ref.read(trackDownloadServiceProvider).downloadMultiple(songs);
          }
        }

        final pushSuccess = await _driveService.pushData();
        if (!pushSuccess) {
          state = state.copyWith(
            isSyncing: false,
            errorMessage: _driveService.lastErrorMessage ?? 'Could not upload data to Google Drive.',
          );
          return false;
        }

        final now = DateTime.now();
        await _settingsNotifier.setLastCloudSyncAt(now);
        state = state.copyWith(
          isSyncing: false,
          lastSyncedAt: now,
          clearErrorMessage: true,
          pendingSyncPlaylistUuids: {},
          pendingSyncSongIds: {},
        );
        return true;
      } else {
        state = state.copyWith(
          isSyncing: false,
          errorMessage: _driveService.lastErrorMessage ?? 'Could not sync with Google Drive.',
        );
        return false;
      }
    } catch (e) {
      Log.e('CloudSyncNotifier: Sync error: $e');
      state = state.copyWith(
        isSyncing: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void schedulePush() {
    if (state.isConnected) {
      _driveService.scheduleDebouncedPush();
    }
  }

  /// Mark a playlist UUID as having pending un-synced changes.
  void markPlaylistPending(String uuid) {
    if (state.isConnected) {
      state = state.copyWith(
        pendingSyncPlaylistUuids: {...state.pendingSyncPlaylistUuids, uuid},
      );
      schedulePush();
    }
  }

  /// Mark a song ID as having pending un-synced changes.
  void markSongPending(String songId) {
    if (state.isConnected) {
      state = state.copyWith(
        pendingSyncSongIds: {...state.pendingSyncSongIds, songId},
      );
      schedulePush();
    }
  }

  /// Clear all pending sync markers (called after successful push).
  void clearAllPending() {
    state = state.copyWith(
      pendingSyncPlaylistUuids: {},
      pendingSyncSongIds: {},
    );
  }
}

final googleDriveSyncServiceProvider = Provider<GoogleDriveSyncService>((ref) {
  final isarService = ref.watch(isarDatabaseServiceProvider);
  return GoogleDriveSyncService(isarService);
});

final cloudSyncProvider = StateNotifierProvider<CloudSyncNotifier, CloudSyncState>((ref) {
  final driveService = ref.watch(googleDriveSyncServiceProvider);
  final settingsNotifier = ref.read(appSettingsProvider.notifier);
  return CloudSyncNotifier(driveService, settingsNotifier, ref);
});

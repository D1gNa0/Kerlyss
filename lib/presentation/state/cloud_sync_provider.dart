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

  const CloudSyncState({
    this.isConnected = false,
    this.isSyncing = false,
    this.userEmail,
    this.lastSyncedAt,
    this.errorMessage,
  });

  CloudSyncState copyWith({
    bool? isConnected,
    bool? isSyncing,
    String? userEmail,
    bool clearUserEmail = false,
    DateTime? lastSyncedAt,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return CloudSyncState(
      isConnected: isConnected ?? this.isConnected,
      isSyncing: isSyncing ?? this.isSyncing,
      userEmail: clearUserEmail ? null : (userEmail ?? this.userEmail),
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
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
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      isConnected.hashCode ^
      isSyncing.hashCode ^
      userEmail.hashCode ^
      lastSyncedAt.hashCode ^
      errorMessage.hashCode;
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

        await _driveService.pushData();
        final now = DateTime.now();
        await _settingsNotifier.setLastCloudSyncAt(now);
        state = state.copyWith(
          isSyncing: false,
          lastSyncedAt: now,
        );
        return true;
      } else {
        state = state.copyWith(
          isSyncing: false,
          errorMessage: 'Could not sync with Google Drive.',
        );
        return false;
      }
    } catch (e) {
      Log.e('CloudSyncNotifier: Sync error: $e');
      state = state.copyWith(
        isSyncing: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void schedulePush() {
    if (state.isConnected) {
      _driveService.scheduleDebouncedPush();
    }
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

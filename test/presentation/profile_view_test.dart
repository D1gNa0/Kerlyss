import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerlyss/domain/entities/downloaded_song.dart';
import 'package:kerlyss/presentation/screens/profile_view.dart';
import 'package:kerlyss/presentation/state/cloud_sync_provider.dart';
import 'package:kerlyss/presentation/state/library_provider.dart';
import 'package:kerlyss/presentation/state/playlist_provider.dart';
import 'package:kerlyss/presentation/state/downloaded_songs_provider.dart';
import 'package:kerlyss/presentation/state/app_settings_provider.dart';

class _MockCloudSyncNotifier extends StateNotifier<CloudSyncState> implements CloudSyncNotifier {
  _MockCloudSyncNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockLibraryNotifier extends StateNotifier<LibraryState> implements LibraryNotifier {
  _MockLibraryNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockPlaylistNotifier extends StateNotifier<PlaylistState> implements PlaylistNotifier {
  _MockPlaylistNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockAppSettingsNotifier extends StateNotifier<AppSettingsState> implements AppSettingsNotifier {
  _MockAppSettingsNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('ProfileView renders local profile and Connect Google Drive button when not connected', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cloudSyncProvider.overrideWith((ref) => _MockCloudSyncNotifier(
                const CloudSyncState(isConnected: false),
              )),
          libraryProvider.overrideWith((ref) => _MockLibraryNotifier(
                const LibraryState(),
              )),
          playlistProvider.overrideWith((ref) => _MockPlaylistNotifier(
                const PlaylistState(),
              )),
          downloadedSongsProvider.overrideWith((ref) => Future.value(<DownloadedSong>[])),
          appSettingsProvider.overrideWith((ref) => _MockAppSettingsNotifier(
                AppSettingsState.initial(),
              )),
        ],
        child: const MaterialApp(
          home: ProfileView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('PROFILE'), findsOneWidget);
    expect(find.text('Local Profile'), findsOneWidget);
    expect(find.text('LOCAL STORAGE ONLY'), findsOneWidget);
    expect(find.text('CONNECT GOOGLE DRIVE'), findsOneWidget);
    expect(find.text('LIBRARY STATS'), findsOneWidget);
    expect(find.text('Playlists'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Offline Tracks'), findsOneWidget);
  });

  testWidgets('ProfileView renders user email, status badge, and Sync Now when connected', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cloudSyncProvider.overrideWith((ref) => _MockCloudSyncNotifier(
                CloudSyncState(
                  isConnected: true,
                  userEmail: 'kerlyss.user@gmail.com',
                  lastSyncedAt: DateTime.now(),
                ),
              )),
          libraryProvider.overrideWith((ref) => _MockLibraryNotifier(
                const LibraryState(),
              )),
          playlistProvider.overrideWith((ref) => _MockPlaylistNotifier(
                const PlaylistState(),
              )),
          downloadedSongsProvider.overrideWith((ref) => Future.value(<DownloadedSong>[])),
          appSettingsProvider.overrideWith((ref) => _MockAppSettingsNotifier(
                AppSettingsState.initial(),
              )),
        ],
        child: const MaterialApp(
          home: ProfileView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('kerlyss.user@gmail.com'), findsOneWidget);
    expect(find.text('GOOGLE DRIVE SYNCED'), findsOneWidget);
    expect(find.text('SYNC NOW'), findsOneWidget);
    expect(find.text('DISCONNECT'), findsOneWidget);
    expect(find.text('K'), findsOneWidget); // User initials avatar
  });
}

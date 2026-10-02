import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerlyss/presentation/common/cloud_sync_status_badge.dart';
import 'package:kerlyss/presentation/state/cloud_sync_provider.dart';

void main() {
  testWidgets('CloudSyncStatusBadge renders nothing when not connected', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cloudSyncProvider.overrideWith((ref) => _MockCloudSyncNotifier(
                const CloudSyncState(isConnected: false),
              )),
        ],
        child: const MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(56),
              child: SafeArea(
                child: Row(
                  children: [CloudSyncStatusBadge()],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Synced'), findsNothing);
    expect(find.text('Syncing...'), findsNothing);
    expect(find.text('Sync error'), findsNothing);
  });

  testWidgets('CloudSyncStatusBadge renders Synced when connected with no pending or errors', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cloudSyncProvider.overrideWith((ref) => _MockCloudSyncNotifier(
                const CloudSyncState(isConnected: true),
              )),
        ],
        child: const MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(56),
              child: SafeArea(
                child: Row(
                  children: [CloudSyncStatusBadge()],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Synced'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);
  });

  testWidgets('CloudSyncStatusBadge renders Syncing... when isSyncing is true', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cloudSyncProvider.overrideWith((ref) => _MockCloudSyncNotifier(
                const CloudSyncState(isConnected: true, isSyncing: true),
              )),
        ],
        child: const MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(56),
              child: SafeArea(
                child: Row(
                  children: [CloudSyncStatusBadge()],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Syncing...'), findsOneWidget);
  });

  testWidgets('CloudSyncStatusBadge renders Sync error and opens dialog on tap', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cloudSyncProvider.overrideWith((ref) => _MockCloudSyncNotifier(
                const CloudSyncState(
                  isConnected: true,
                  errorMessage: 'Google Drive API is disabled in Cloud Console.',
                ),
              )),
        ],
        child: const MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(56),
              child: SafeArea(
                child: Row(
                  children: [CloudSyncStatusBadge()],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Sync error'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

    await tester.tap(find.text('Sync error'));
    await tester.pumpAndSettle();

    expect(find.text('CLOUD SYNC ERROR'), findsOneWidget);
    expect(find.text('Google Drive API is disabled in Cloud Console.'), findsOneWidget);
    expect(find.text('DISMISS'), findsOneWidget);
    expect(find.text('RETRY'), findsOneWidget);
  });

  testWidgets('CloudSyncStatusBadge renders pending count when pending items exist', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cloudSyncProvider.overrideWith((ref) => _MockCloudSyncNotifier(
                const CloudSyncState(
                  isConnected: true,
                  pendingSyncPlaylistUuids: {'uuid-1', 'uuid-2'},
                  pendingSyncSongIds: {'song-1'},
                ),
              )),
        ],
        child: const MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(56),
              child: SafeArea(
                child: Row(
                  children: [CloudSyncStatusBadge()],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('3 pending'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_upload_rounded), findsOneWidget);
  });
}

class _MockCloudSyncNotifier extends StateNotifier<CloudSyncState>
    implements CloudSyncNotifier {
  _MockCloudSyncNotifier(super.state);

  @override
  Future<bool> syncNow() async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

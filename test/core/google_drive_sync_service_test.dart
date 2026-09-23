import 'package:flutter_test/flutter_test.dart';
import 'package:kerlyss/core/services/google_drive_sync_service.dart';
import 'package:kerlyss/data/datasources/local/isar_database_service.dart';
import 'package:kerlyss/data/models/app_settings_model.dart';
import 'package:kerlyss/main.dart';
import 'package:kerlyss/presentation/state/app_settings_provider.dart';
import 'package:kerlyss/presentation/state/cloud_sync_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockIsarDatabaseService extends Mock implements IsarDatabaseService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoogleDriveSyncService Specs', () {
    late MockIsarDatabaseService mockIsar;
    late GoogleDriveSyncService syncService;

    setUp(() {
      mockIsar = MockIsarDatabaseService();
      syncService = GoogleDriveSyncService(mockIsar);
      AetherHttpOverrides.isOfflineMode = false;
    });

    test('syncFileName and scope are correctly defined', () {
      expect(GoogleDriveSyncService.syncFileName, equals('kerlyss_sync.json'));
      expect(GoogleDriveSyncService.appDataScope, equals('https://www.googleapis.com/auth/drive.appdata'));
    });

    test('offline mode blocks pullAndMerge and returns false immediately', () async {
      AetherHttpOverrides.isOfflineMode = true;
      final result = await syncService.pullAndMerge();
      expect(result, isFalse);
    });

    test('offline mode blocks pushData and returns false immediately', () async {
      AetherHttpOverrides.isOfflineMode = true;
      final result = await syncService.pushData();
      expect(result, isFalse);
    });

    test('offline mode blocks silentSignIn and returns false immediately', () async {
      AetherHttpOverrides.isOfflineMode = true;
      final result = await syncService.silentSignIn();
      expect(result, isFalse);
    });

    test('CloudSyncState copyWith preserves values and updates correctly', () {
      const state1 = CloudSyncState(
        isConnected: false,
        isSyncing: false,
        userEmail: null,
      );

      final state2 = state1.copyWith(
        isConnected: true,
        userEmail: 'user@gmail.com',
      );

      expect(state2.isConnected, isTrue);
      expect(state2.userEmail, equals('user@gmail.com'));
      expect(state2.isSyncing, isFalse);

      final state3 = state2.copyWith(clearUserEmail: true, isConnected: false);
      expect(state3.isConnected, isFalse);
      expect(state3.userEmail, isNull);
    });

    test('AppSettingsModel persists cloud sync fields', () {
      final model = AppSettingsModel();
      expect(model.cloudSyncEnabled, isFalse);
      expect(model.googleAccountEmail, isNull);
      expect(model.lastCloudSyncAt, isNull);

      model.cloudSyncEnabled = true;
      model.googleAccountEmail = 'test@gmail.com';
      final now = DateTime.now();
      model.lastCloudSyncAt = now;

      final state = AppSettingsState.fromModel(model);
      expect(state.cloudSyncEnabled, isTrue);
      expect(state.googleAccountEmail, equals('test@gmail.com'));
      expect(state.lastCloudSyncAt, equals(now));

      final convertedModel = state.toModel();
      expect(convertedModel.cloudSyncEnabled, isTrue);
      expect(convertedModel.googleAccountEmail, equals('test@gmail.com'));
      expect(convertedModel.lastCloudSyncAt, equals(now));
    });
  });
}

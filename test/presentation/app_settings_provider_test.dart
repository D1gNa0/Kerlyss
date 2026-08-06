import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:kerlyss/core/services/app_storage_paths.dart';
import 'package:kerlyss/data/datasources/local/isar_database_service.dart';
import 'package:kerlyss/data/models/app_settings_model.dart';
import 'package:kerlyss/presentation/state/app_settings_provider.dart';

class FakeIsarDatabaseService implements IsarDatabaseService {
  AppSettingsModel savedModel = AppSettingsModel();
  bool shouldThrowOnSave = false;

  @override
  late Isar isar;

  @override
  Future<AppSettingsModel> getSettings() async {
    return savedModel;
  }

  @override
  Future<void> saveSettings(AppSettingsModel settings) async {
    if (shouldThrowOnSave) {
      throw Exception('Database write error');
    }
    savedModel = settings;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppSettingsState & AppSettingsNotifier', () {
    late FakeIsarDatabaseService fakeIsar;

    setUp(() {
      fakeIsar = FakeIsarDatabaseService();
      AppStoragePaths.customDownloadsPath = null;
    });

    test('initial state matches AppSettingsModel defaults', () {
      final state = AppSettingsState.initial();
      expect(state.customDownloadsPath, isNull);
      expect(state.audioQuality, equals('High (320kbps)'));
      expect(state.gaplessPlayback, isTrue);
      expect(state.equalizerEnabled, isFalse);
      expect(state.eqPreset, equals('Flat'));
      expect(state.eqBandGains, equals([0.0, 0.0, 0.0, 0.0, 0.0]));
      expect(state.theme, equals('Deep Matte'));
      expect(state.animationsEnabled, isTrue);
    });

    test('loads saved settings from IsarDatabaseService on initialization', () async {
      fakeIsar.savedModel = AppSettingsModel()
        ..customDownloadsPath = '/custom/path'
        ..audioQuality = 'Lossless (FLAC)'
        ..gaplessPlayback = false
        ..equalizerEnabled = true
        ..eqPreset = 'Rock'
        ..eqBandGains = [2.0, 1.0, 0.0, 1.0, 2.0]
        ..theme = 'Light'
        ..animationsEnabled = false;

      final notifier = AppSettingsNotifier(fakeIsar);
      await Future.delayed(const Duration(milliseconds: 50));

      final state = notifier.state;
      expect(state.customDownloadsPath, equals('/custom/path'));
      expect(state.audioQuality, equals('Lossless (FLAC)'));
      expect(state.gaplessPlayback, isFalse);
      expect(state.equalizerEnabled, isTrue);
      expect(state.eqPreset, equals('Rock'));
      expect(state.eqBandGains, equals([2.0, 1.0, 0.0, 1.0, 2.0]));
      expect(state.theme, equals('Light'));
      expect(state.animationsEnabled, isFalse);
    });

    test('updates state and persists to IsarDatabaseService when setting changed', () async {
      final notifier = AppSettingsNotifier(fakeIsar);
      await Future.delayed(const Duration(milliseconds: 20));

      await notifier.setAudioQuality('Low (128kbps)');
      expect(notifier.state.audioQuality, equals('Low (128kbps)'));
      expect(fakeIsar.savedModel.audioQuality, equals('Low (128kbps)'));

      await notifier.setEqualizerEnabled(true);
      expect(notifier.state.equalizerEnabled, isTrue);
      expect(fakeIsar.savedModel.equalizerEnabled, isTrue);

      await notifier.setEqPreset('Vocal');
      expect(notifier.state.eqPreset, equals('Vocal'));
      expect(fakeIsar.savedModel.eqPreset, equals('Vocal'));

      await notifier.setEqBandGains([1.0, 2.0, 3.0, 4.0, 5.0]);
      expect(notifier.state.eqBandGains, equals([1.0, 2.0, 3.0, 4.0, 5.0]));
      expect(fakeIsar.savedModel.eqBandGains, equals([1.0, 2.0, 3.0, 4.0, 5.0]));

      await notifier.setCustomDownloadsPath('/my/downloads');
      expect(notifier.state.customDownloadsPath, equals('/my/downloads'));
      expect(fakeIsar.savedModel.customDownloadsPath, equals('/my/downloads'));
      expect(AppStoragePaths.customDownloadsPath, equals('/my/downloads'));

      await notifier.setCustomDownloadsPath('   ');
      expect(notifier.state.customDownloadsPath, isNull);
      expect(fakeIsar.savedModel.customDownloadsPath, isNull);
      expect(AppStoragePaths.customDownloadsPath, isNull);
    });

    test('handles save errors gracefully with logging', () async {
      fakeIsar.shouldThrowOnSave = true;
      final notifier = AppSettingsNotifier(fakeIsar);
      await Future.delayed(const Duration(milliseconds: 20));

      // Should not throw unhandled exception
      await notifier.setAudioQuality('Low (128kbps)');
      expect(notifier.state.audioQuality, equals('Low (128kbps)'));
    });
  });
}

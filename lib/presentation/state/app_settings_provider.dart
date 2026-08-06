import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_storage_paths.dart';
import '../../data/datasources/local/isar_database_service.dart';
import '../../data/models/app_settings_model.dart';
import '../../data/repositories/repository_providers.dart';

class AppSettingsState {
  final String? customDownloadsPath;
  final String audioQuality;
  final bool gaplessPlayback;
  final bool equalizerEnabled;
  final String eqPreset;
  final List<double> eqBandGains;
  final String theme;
  final bool animationsEnabled;

  const AppSettingsState({
    this.customDownloadsPath,
    required this.audioQuality,
    required this.gaplessPlayback,
    required this.equalizerEnabled,
    required this.eqPreset,
    required this.eqBandGains,
    required this.theme,
    required this.animationsEnabled,
  });

  factory AppSettingsState.initial() => const AppSettingsState(
        customDownloadsPath: null,
        audioQuality: 'High (320kbps)',
        gaplessPlayback: true,
        equalizerEnabled: false,
        eqPreset: 'Flat',
        eqBandGains: [0.0, 0.0, 0.0, 0.0, 0.0],
        theme: 'Deep Matte',
        animationsEnabled: true,
      );

  factory AppSettingsState.fromModel(AppSettingsModel model) => AppSettingsState(
        customDownloadsPath: model.customDownloadsPath,
        audioQuality: model.audioQuality,
        gaplessPlayback: model.gaplessPlayback,
        equalizerEnabled: model.equalizerEnabled,
        eqPreset: model.eqPreset,
        eqBandGains: List<double>.from(model.eqBandGains),
        theme: model.theme,
        animationsEnabled: model.animationsEnabled,
      );

  AppSettingsModel toModel() {
    return AppSettingsModel()
      ..id = 1
      ..customDownloadsPath = customDownloadsPath
      ..audioQuality = audioQuality
      ..gaplessPlayback = gaplessPlayback
      ..equalizerEnabled = equalizerEnabled
      ..eqPreset = eqPreset
      ..eqBandGains = List<double>.from(eqBandGains)
      ..theme = theme
      ..animationsEnabled = animationsEnabled;
  }

  AppSettingsState copyWith({
    String? customDownloadsPath,
    bool clearCustomDownloadsPath = false,
    String? audioQuality,
    bool? gaplessPlayback,
    bool? equalizerEnabled,
    String? eqPreset,
    List<double>? eqBandGains,
    String? theme,
    bool? animationsEnabled,
  }) {
    return AppSettingsState(
      customDownloadsPath: clearCustomDownloadsPath
          ? null
          : (customDownloadsPath ?? this.customDownloadsPath),
      audioQuality: audioQuality ?? this.audioQuality,
      gaplessPlayback: gaplessPlayback ?? this.gaplessPlayback,
      equalizerEnabled: equalizerEnabled ?? this.equalizerEnabled,
      eqPreset: eqPreset ?? this.eqPreset,
      eqBandGains: eqBandGains ?? this.eqBandGains,
      theme: theme ?? this.theme,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsState &&
          runtimeType == other.runtimeType &&
          customDownloadsPath == other.customDownloadsPath &&
          audioQuality == other.audioQuality &&
          gaplessPlayback == other.gaplessPlayback &&
          equalizerEnabled == other.equalizerEnabled &&
          eqPreset == other.eqPreset &&
          listEquals(eqBandGains, other.eqBandGains) &&
          theme == other.theme &&
          animationsEnabled == other.animationsEnabled;

  @override
  int get hashCode =>
      customDownloadsPath.hashCode ^
      audioQuality.hashCode ^
      gaplessPlayback.hashCode ^
      equalizerEnabled.hashCode ^
      eqPreset.hashCode ^
      Object.hashAll(eqBandGains) ^
      theme.hashCode ^
      animationsEnabled.hashCode;
}

class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  final IsarDatabaseService _isarService;

  AppSettingsNotifier(this._isarService) : super(AppSettingsState.initial()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final model = await _isarService.getSettings();
      state = AppSettingsState.fromModel(model);
      AppStoragePaths.customDownloadsPath = state.customDownloadsPath;
    } catch (_) {}
  }

  Future<void> _saveSettings(AppSettingsState newState) async {
    state = newState;
    try {
      await _isarService.saveSettings(newState.toModel());
    } catch (_) {}
  }

  Future<void> setAudioQuality(String val) async {
    await _saveSettings(state.copyWith(audioQuality: val));
  }

  Future<void> setGaplessPlayback(bool enabled) async {
    await _saveSettings(state.copyWith(gaplessPlayback: enabled));
  }

  Future<void> toggleGapless() async {
    await _saveSettings(state.copyWith(gaplessPlayback: !state.gaplessPlayback));
  }

  Future<void> setEqualizerEnabled(bool enabled) async {
    await _saveSettings(state.copyWith(equalizerEnabled: enabled));
  }

  Future<void> setEqPreset(String preset) async {
    await _saveSettings(state.copyWith(eqPreset: preset));
  }

  Future<void> setEqBandGains(List<double> gains) async {
    await _saveSettings(state.copyWith(eqBandGains: gains));
  }

  Future<void> setTheme(String val) async {
    await _saveSettings(state.copyWith(theme: val));
  }

  Future<void> setAnimationsEnabled(bool enabled) async {
    await _saveSettings(state.copyWith(animationsEnabled: enabled));
  }

  Future<void> toggleAnimations() async {
    await _saveSettings(state.copyWith(animationsEnabled: !state.animationsEnabled));
  }

  Future<void> setCustomDownloadsPath(String? path) async {
    AppStoragePaths.customDownloadsPath = path;
    if (path == null) {
      await _saveSettings(state.copyWith(clearCustomDownloadsPath: true));
    } else {
      await _saveSettings(state.copyWith(customDownloadsPath: path));
    }
  }
}

final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettingsState>((ref) {
  final isarService = ref.watch(isarDatabaseServiceProvider);
  return AppSettingsNotifier(isarService);
});

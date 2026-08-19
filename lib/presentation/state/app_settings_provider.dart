import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_storage_paths.dart';
import '../../core/services/logger_service.dart';
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
  final List<String> dislikedSongIds;
  final List<String> dislikedArtists;

  const AppSettingsState({
    this.customDownloadsPath,
    required this.audioQuality,
    required this.gaplessPlayback,
    required this.equalizerEnabled,
    required this.eqPreset,
    required this.eqBandGains,
    required this.theme,
    required this.animationsEnabled,
    this.dislikedSongIds = const [],
    this.dislikedArtists = const [],
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
        dislikedSongIds: [],
        dislikedArtists: [],
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
        dislikedSongIds: List<String>.from(model.dislikedSongIds),
        dislikedArtists: List<String>.from(model.dislikedArtists),
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
      ..animationsEnabled = animationsEnabled
      ..dislikedSongIds = List<String>.from(dislikedSongIds)
      ..dislikedArtists = List<String>.from(dislikedArtists);
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
    List<String>? dislikedSongIds,
    List<String>? dislikedArtists,
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
      dislikedSongIds: dislikedSongIds ?? this.dislikedSongIds,
      dislikedArtists: dislikedArtists ?? this.dislikedArtists,
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
          animationsEnabled == other.animationsEnabled &&
          listEquals(dislikedSongIds, other.dislikedSongIds) &&
          listEquals(dislikedArtists, other.dislikedArtists);

  @override
  int get hashCode =>
      customDownloadsPath.hashCode ^
      audioQuality.hashCode ^
      gaplessPlayback.hashCode ^
      equalizerEnabled.hashCode ^
      eqPreset.hashCode ^
      Object.hashAll(eqBandGains) ^
      theme.hashCode ^
      animationsEnabled.hashCode ^
      Object.hashAll(dislikedSongIds) ^
      Object.hashAll(dislikedArtists);
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
    } catch (e, stackTrace) {
      Log.e('Failed to load app settings from Isar: $e', e, stackTrace);
    }
  }

  Future<void> _saveSettings(AppSettingsState newState) async {
    state = newState;
    try {
      await _isarService.saveSettings(newState.toModel());
    } catch (e, stackTrace) {
      Log.e('Failed to save app settings to Isar: $e', e, stackTrace);
    }
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
    final cleanPath = (path?.trim().isEmpty ?? true) ? null : path!.trim();
    AppStoragePaths.customDownloadsPath = cleanPath;
    if (cleanPath == null) {
      await _saveSettings(state.copyWith(clearCustomDownloadsPath: true));
    } else {
      await _saveSettings(state.copyWith(customDownloadsPath: cleanPath));
    }
  }

  Future<void> addDislikedSong(String songId) async {
    if (songId.isEmpty || state.dislikedSongIds.contains(songId)) return;
    final updated = List<String>.from(state.dislikedSongIds)..add(songId);
    await _saveSettings(state.copyWith(dislikedSongIds: updated));
  }

  Future<void> addDislikedArtist(String artistName) async {
    final clean = artistName.trim();
    if (clean.isEmpty || state.dislikedArtists.contains(clean)) return;
    final updated = List<String>.from(state.dislikedArtists)..add(clean);
    await _saveSettings(state.copyWith(dislikedArtists: updated));
  }
}

final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettingsState>((ref) {
  final isarService = ref.watch(isarDatabaseServiceProvider);
  return AppSettingsNotifier(isarService);
});

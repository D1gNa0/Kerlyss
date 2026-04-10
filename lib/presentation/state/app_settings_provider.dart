import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppSettingsState {
  final String audioQuality;
  final bool gaplessPlayback;
  final String equalizer;
  final String theme;
  final bool animationsEnabled;

  const AppSettingsState({
    required this.audioQuality,
    required this.gaplessPlayback,
    required this.equalizer,
    required this.theme,
    required this.animationsEnabled,
  });

  factory AppSettingsState.initial() => const AppSettingsState(
        audioQuality: 'High (320kbps)',
        gaplessPlayback: true,
        equalizer: 'Aether Default',
        theme: 'Deep Matte',
        animationsEnabled: true,
      );

  AppSettingsState copyWith({
    String? audioQuality,
    bool? gaplessPlayback,
    String? equalizer,
    String? theme,
    bool? animationsEnabled,
  }) {
    return AppSettingsState(
      audioQuality: audioQuality ?? this.audioQuality,
      gaplessPlayback: gaplessPlayback ?? this.gaplessPlayback,
      equalizer: equalizer ?? this.equalizer,
      theme: theme ?? this.theme,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  AppSettingsNotifier() : super(AppSettingsState.initial());

  void setAudioQuality(String val) => state = state.copyWith(audioQuality: val);
  void toggleGapless() => state = state.copyWith(gaplessPlayback: !state.gaplessPlayback);
  void setTheme(String val) => state = state.copyWith(theme: val);
  void toggleAnimations() => state = state.copyWith(animationsEnabled: !state.animationsEnabled);
}

final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettingsState>((ref) {
  return AppSettingsNotifier();
});

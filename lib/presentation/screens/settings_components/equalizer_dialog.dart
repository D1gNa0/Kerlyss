import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerlyss/presentation/theme/aether_colors.dart';
import 'package:kerlyss/presentation/common/aether_glass.dart';
import 'package:kerlyss/presentation/state/app_settings_provider.dart';
import 'package:kerlyss/presentation/state/audio_provider.dart';
import 'package:kerlyss/main.dart';

class EqualizerDialog extends ConsumerWidget {
  const EqualizerDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final eqBands = ['60Hz', '230Hz', '910Hz', '4kHz', '14kHz'];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: AetherGlass(
        borderRadius: 24,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.equalizer_rounded, color: AetherColors.accentCyan, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'AUDIO EQUALIZER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: settings.equalizerEnabled,
                  activeColor: AetherColors.accentCyan,
                  onChanged: (enabled) async {
                    await ref.read(appSettingsProvider.notifier).setEqualizerEnabled(enabled);
                    final eq = globalAudioHandler.equalizer;
                    if (eq != null) {
                      await eq.setEnabled(enabled);
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (settings.equalizerEnabled) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Preset', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  DropdownButton<String>(
                    value: settings.eqPreset,
                    dropdownColor: AetherColors.ultraDarkGray,
                    style: const TextStyle(color: AetherColors.accentCyan, fontSize: 12, fontWeight: FontWeight.bold),
                    items: ['Flat', 'Bass Boost', 'Vocal', 'Electronic', 'Rock', 'Custom']
                        .map((preset) => DropdownMenuItem(value: preset, child: Text(preset)))
                        .toList(),
                    onChanged: (newPreset) async {
                      if (newPreset != null && newPreset != 'Custom') {
                        await ref.read(appSettingsProvider.notifier).setEqPreset(newPreset);
                        ref.read(audioProvider.notifier).setEqPreset(newPreset);
                        
                        final Map<String, List<double>> presets = {
                          'Flat': [0.0, 0.0, 0.0, 0.0, 0.0],
                          'Bass Boost': [5.0, 3.0, 0.0, 0.0, -1.0],
                          'Vocal': [-2.0, 0.0, 3.0, 4.0, 1.0],
                          'Electronic': [4.0, 1.5, 0.0, 2.5, 3.5],
                          'Rock': [3.0, 1.5, -1.0, 2.0, 4.0],
                        };
                        if (presets.containsKey(newPreset)) {
                          await ref.read(appSettingsProvider.notifier).setEqBandGains(presets[newPreset]!);
                        }
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Band Sliders (60Hz, 230Hz, 910Hz, 4kHz, 14kHz)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  final gain = index < settings.eqBandGains.length ? settings.eqBandGains[index] : 0.0;

                  return Column(
                    children: [
                      Text('${gain.toStringAsFixed(1)}dB', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                      SizedBox(
                        height: 140,
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                              activeTrackColor: AetherColors.accentCyan,
                              inactiveTrackColor: Colors.white12,
                              thumbColor: Colors.white,
                            ),
                            child: Slider(
                              value: gain.clamp(-15.0, 15.0),
                              min: -15.0,
                              max: 15.0,
                              onChanged: settings.equalizerEnabled
                                  ? (val) async {
                                      final newGains = List<double>.from(settings.eqBandGains);
                                      newGains[index] = val;
                                      await ref.read(appSettingsProvider.notifier).setEqBandGains(newGains);
                                      await ref.read(appSettingsProvider.notifier).setEqPreset('Custom');
                                      
                                      final eq = globalAudioHandler.equalizer;
                                      if (eq != null) {
                                        try {
                                          final params = await eq.parameters;
                                          if (index < params.bands.length) {
                                            await params.bands[index].setGain(val);
                                          }
                                        } catch (_) {}
                                      }
                                    }
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        eqBands[index],
                        style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                    ],
                  );
                }),
              ),
            ] else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'Equalizer is disabled.\nToggle switch above to enable.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white30, fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

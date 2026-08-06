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
      child: AetherGlass(
        borderRadius: 24,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'EQUALIZER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Switch(
                  value: settings.equalizerEnabled,
                  activeColor: AetherColors.accentCyan,
                  onChanged: (val) async {
                    await ref.read(appSettingsProvider.notifier).setEqualizerEnabled(val);
                    final eq = globalAudioHandler.equalizer;
                    if (eq != null) {
                      await eq.setEnabled(val);
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
                    value: settings.equalizer,
                    dropdownColor: AetherColors.ultraDarkGray,
                    style: const TextStyle(color: AetherColors.accentCyan, fontSize: 12, fontWeight: FontWeight.bold),
                    items: ['Flat', 'Bass Boost', 'Vocal', 'Electronic', 'Rock', 'Custom']
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (newPreset) async {
                      if (newPreset != null && newPreset != 'Custom') {
                        await ref.read(appSettingsProvider.notifier).setEqualizerPreset(newPreset);
                        ref.read(audioProvider.notifier).setEqPreset(newPreset);
                        
                        final Map<String, List<double>> presets = {
                          'Flat': [0.0, 0.0, 0.0, 0.0, 0.0],
                          'Bass Boost': [5.0, 3.0, 0.0, 0.0, -1.0],
                          'Vocal': [-2.0, 0.0, 3.0, 4.0, 1.0],
                          'Electronic': [4.0, 1.5, 0.0, 2.5, 3.5],
                          'Rock': [3.0, 1.5, -1.0, 2.0, 4.0],
                        };
                        await ref.read(appSettingsProvider.notifier).setEqBandGains(presets[newPreset]!);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 180,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(eqBands.length, (index) {
                    final currentGain = settings.eqBandGains[index];
                    return Column(
                      children: [
                        Text(
                          '${currentGain.round() > 0 ? "+" : ""}${currentGain.round()}dB',
                          style: const TextStyle(color: Colors.white54, fontSize: 9),
                        ),
                        Expanded(
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: Slider(
                              value: currentGain.clamp(-15.0, 15.0),
                              min: -15.0,
                              max: 15.0,
                              activeColor: AetherColors.accentCyan,
                              inactiveColor: Colors.white10,
                              onChanged: (val) async {
                                final newGains = List<double>.from(settings.eqBandGains);
                                newGains[index] = val;
                                await ref.read(appSettingsProvider.notifier).setEqBandGains(newGains);
                                await ref.read(appSettingsProvider.notifier).setEqualizerPreset('Custom');
                                
                                final eq = globalAudioHandler.equalizer;
                                if (eq != null) {
                                  try {
                                    final params = await eq.parameters;
                                    if (index < params.bands.length) {
                                      await params.bands[index].setGain(val);
                                    }
                                  } catch (_) {}
                                }
                              },
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

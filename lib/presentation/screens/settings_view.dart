import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/aether_colors.dart';
import '../common/aether_glass.dart';
import '../state/app_settings_provider.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      backgroundColor: AetherColors.deepMatteBlack,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'SETTINGS',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 12,
                letterSpacing: 4,
              ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _SettingsSection(
            title: 'AUDIO',
            children: [
              _SettingsTile(
                label: 'Audio Quality', 
                value: settings.audioQuality,
                onTap: () {
                  ref.read(appSettingsProvider.notifier).setAudioQuality(
                    settings.audioQuality == 'High (320kbps)' ? 'Standard (128kbps)' : 'High (320kbps)'
                  );
                },
              ),
              _SettingsTile(
                label: 'Gapless Playback', 
                value: settings.gaplessPlayback ? 'Enabled' : 'Disabled',
                onTap: () => ref.read(appSettingsProvider.notifier).toggleGapless(),
              ),
              _SettingsTile(
                label: 'Equalizer', 
                value: settings.equalizer,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 32),
          _SettingsSection(
            title: 'INTERFACE',
            children: [
              _SettingsTile(
                label: 'Theme', 
                value: settings.theme,
                onTap: () {
                  ref.read(appSettingsProvider.notifier).setTheme(
                    settings.theme == 'Deep Matte' ? 'Light mode (Sacrilege)' : 'Deep Matte'
                  );
                },
              ),
              _SettingsTile(
                label: 'Animations', 
                value: settings.animationsEnabled ? 'Fluid (60Hz+)' : 'Reduced',
                onTap: () => ref.read(appSettingsProvider.notifier).toggleAnimations(),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _SettingsSection(
            title: 'ABOUT',
            children: [
              _SettingsTile(label: 'Version', value: '0.5.0-Alpha'),
              _SettingsTile(label: 'Build', value: 'Architect-Preview'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 10,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        AetherGlass(
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SettingsTile({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: AetherColors.textSecondary, fontSize: 12)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 18),
        ],
      ),
      onTap: onTap,
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/aether_colors.dart';
import '../common/aether_glass.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AetherColors.deepMatteBlack,
      appBar: AppBar(
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
              _SettingsTile(label: 'Audio Quality', value: 'High (320kbps)'),
              _SettingsTile(label: 'Gapless Playback', value: 'Enabled'),
              _SettingsTile(label: 'Equalizer', value: 'Aether Default'),
            ],
          ),
          const SizedBox(height: 32),
          _SettingsSection(
            title: 'INTERFACE',
            children: [
              _SettingsTile(label: 'Theme', value: 'Deep Matte'),
              _SettingsTile(label: 'Animations', value: 'Fluid (60Hz+)'),
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

  const _SettingsTile({required this.label, required this.value});

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
      onTap: () {},
    );
  }
}

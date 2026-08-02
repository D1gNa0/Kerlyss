import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/aether_colors.dart';
import '../common/aether_glass.dart';
import '../state/audio_provider.dart';
import '../../core/services/update_service.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          if (!kIsWeb && Platform.isWindows) ...[
            const _SettingsSection(
              title: 'PLAYBACK CONTROLS',
              children: [
                _ShortcutTile(label: 'Play / Pause', value: 'Space'),
                _ShortcutTile(label: 'Seek Forward 5s', value: '→ Arrow'),
                _ShortcutTile(label: 'Seek Backward 5s', value: '← Arrow'),
                _ShortcutTile(label: 'Next track', value: 'Ctrl + →'),
                _ShortcutTile(label: 'Previous track', value: 'Ctrl + ←'),
              ],
            ),
            const SizedBox(height: 32),
          ],
          _SettingsSection(
            title: 'AUDIO FX & EQUALIZER',
            children: [
              _EqPresetTile(),
            ],
          ),
          const SizedBox(height: 32),
          _SettingsSection(
            title: 'APPLICATION',
            children: [
              _SettingsTile(
                label: 'Window Style', 
                value: 'Shadow Glass',
                onTap: () {},
              ),
              _SettingsTile(
                label: 'Downloads Folder', 
                value: 'User/Documents/Kerlyss',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 32),
          _SettingsSection(
            title: 'ABOUT',
            children: [
              _SettingsTile(
                label: 'Official Website',
                value: 'unexpectedd0.github.io/Kerlyss-Release',
                onTap: () async {
                  final url = Uri.parse('https://unexpectedd0.github.io/Kerlyss-Release/');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              _SettingsTile(
                label: 'Developer Instagram',
                value: '@melihkerema',
                onTap: () async {
                  final url = Uri.parse('https://www.instagram.com/melihkerema/');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final version = snapshot.data?.version ?? '...';
                  return _SettingsTile(
                    label: 'Version', 
                    value: version, 
                    onTap: () {},
                  );
                },
              ),
              _SettingsTile(
                label: 'Check for Updates',
                value: 'Tap to check',
                onTap: () => UpdateService().checkForUpdates(context),
              ),
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
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 10,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        AetherGlass(
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
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
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, letterSpacing: 0.5)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: AetherColors.textSecondary, fontSize: 11)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 16),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _EqPresetTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioProvider);
    const presets = ['Flat', 'Bass Boost', 'Vocal', 'Electronic', 'Rock'];

    return ListTile(
      title: const Text('Equalizer Preset', style: TextStyle(color: Colors.white, fontSize: 13, letterSpacing: 0.5)),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: presets.contains(audioState.eqPreset) ? audioState.eqPreset : 'Flat',
          dropdownColor: AetherColors.ultraDarkGray,
          style: const TextStyle(color: AetherColors.accentCyan, fontSize: 11, fontWeight: FontWeight.bold),
          items: presets.map((p) {
            return DropdownMenuItem<String>(
              value: p,
              child: Text(p),
            );
          }).toList(),
          onChanged: (newPreset) {
            if (newPreset != null) {
              ref.read(audioProvider.notifier).setEqPreset(newPreset);
            }
          },
        ),
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  final String label;
  final String value;

  const _ShortcutTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, letterSpacing: 0.5)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(
          value, 
          style: const TextStyle(
            color: AetherColors.accentCyan, 
            fontSize: 10, 
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}


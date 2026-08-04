import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/aether_colors.dart';
import '../common/aether_glass.dart';
import '../state/audio_provider.dart';
import '../../core/services/app_storage_paths.dart';
import '../../core/services/update_service.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 100;

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
        padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPadding),
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
            const SizedBox(height: 28),
          ],
          _SettingsSection(
            title: 'AUDIO FX & EQUALIZER',
            children: [
              _EqPresetTile(),
            ],
          ),
          if (!kIsWeb) ...[
            const SizedBox(height: 28),
            _SettingsSection(
              title: 'APPLICATION',
              children: [
                if (Platform.isWindows || Platform.isMacOS)
                  _SettingsTile(
                    label: 'Window Style', 
                    value: 'Shadow Glass',
                    onTap: () {},
                  ),
                FutureBuilder<Directory>(
                  future: AppStoragePaths.downloadsDirectory(),
                  builder: (context, snapshot) {
                    final path = snapshot.data?.path ?? 'Loading...';
                    return _SettingsTile(
                      label: 'Downloads Folder', 
                      value: path,
                      icon: Icons.folder_open_rounded,
                      onTap: () async {
                        if (snapshot.hasData) {
                          try {
                            final uri = Uri.directory(snapshot.data!.path);
                            await launchUrl(uri);
                          } catch (_) {}
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ],
          const SizedBox(height: 28),
          _SettingsSection(
            title: 'ABOUT',
            children: [
              _SettingsTile(
                label: 'Support the Developer',
                value: 'Buy me a coffee ☕',
                icon: Icons.favorite_rounded,
                onTap: () => _openUrl('https://patreon.com/your_username_here'), // TODO: Replace with your actual Patreon link
              ),
              _SettingsTile(
                label: 'Official Website',
                value: 'd1gna0.github.io/Kerlyss',
                icon: Icons.language_rounded,
                onTap: () => _openUrl('https://d1gna0.github.io/Kerlyss/'),
              ),
              _SettingsTile(
                label: 'Developer Instagram',
                value: '@melihkerema',
                icon: Icons.camera_alt_rounded,
                onTap: () => _openUrl('https://www.instagram.com/melihkerema/'),
              ),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final version = snapshot.data?.version ?? '...';
                  return _SettingsTile(
                    label: 'Version', 
                    value: version,
                    icon: Icons.info_outline_rounded,
                    onTap: () {},
                  );
                },
              ),
              _SettingsTile(
                label: 'Check for Updates',
                value: 'Tap to check',
                icon: Icons.system_update_rounded,
                onTap: () => UpdateService().checkForUpdates(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Failed to launch URL $urlString: $e');
    }
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
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        AetherGlass(
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(vertical: 4),
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
  final IconData? icon;

  const _SettingsTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isLongText = value.length > 18;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white70, size: 18),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  if (isLongText) ...[
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(color: AetherColors.textSecondary, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (!isLongText) ...[
              Text(
                value,
                style: const TextStyle(color: AetherColors.textSecondary, fontSize: 11),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}

class _EqPresetTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioProvider);
    const presets = ['Flat', 'Bass Boost', 'Vocal', 'Electronic', 'Rock'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.tune_rounded, color: Colors.white70, size: 18),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Equalizer Preset',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          DropdownButtonHideUnderline(
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
        ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Container(
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
        ],
      ),
    );
  }
}


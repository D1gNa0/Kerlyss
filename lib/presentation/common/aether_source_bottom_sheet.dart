import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/aether_colors.dart';
import '../state/discovery_search_provider.dart';
import '../../core/services/logger_service.dart';
import 'vercel_hover_button.dart';

class AetherSourceBottomSheet extends ConsumerWidget {
  const AetherSourceBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        height: 300,
        decoration: const BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'IMPORT SOURCE',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 12,
                    letterSpacing: 4,
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SourceOption(
                  icon: Icons.search_rounded,
                  label: 'SEARCH',
                  onTap: () {
                    Log.d('Source bottom sheet: SEARCH tapped');
                    ref.read(discoverySearchProvider.notifier).setSearchMode(SearchMode.songs);
                    Navigator.pop(context);
                  },
                ),
                _SourceOption(
                  icon: Icons.link_rounded,
                  label: 'SPOTIFY',
                  onTap: () {
                    Log.d('Source bottom sheet: SPOTIFY tapped');
                    ref.read(discoverySearchProvider.notifier).setSearchMode(SearchMode.spotifyImport);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceOption extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceOption({required this.icon, required this.label, required this.onTap});

  @override
  State<_SourceOption> createState() => _SourceOptionState();
}

class _SourceOptionState extends State<_SourceOption> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isHovered ? AetherColors.primaryAccent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
                border: Border.all(
                  color: _isHovered ? AetherColors.primaryAccent.withValues(alpha: 0.6) : Colors.white12,
                  width: _isHovered ? 1.5 : 1.0,
                ),
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  color: _isHovered ? AetherColors.primaryAccent : Colors.white,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    color: _isHovered ? Colors.white : AetherColors.textSecondary,
                    fontWeight: _isHovered ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

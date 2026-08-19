import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/navigation_provider.dart';
import '../theme/aether_colors.dart';
import 'aether_glass.dart';

class AetherBottomNav extends ConsumerWidget {
  const AetherBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationProvider);

    final isMobile = Theme.of(context).platform == TargetPlatform.android || 
                    Theme.of(context).platform == TargetPlatform.iOS;

    return Container(
      height: 62,
      margin: EdgeInsets.fromLTRB(
        isMobile ? 12 : 40, 
        0, 
        isMobile ? 12 : 40, 
        isMobile ? 8 : 16,
      ),
      child: AetherGlass(
        borderRadius: 31,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                label: 'Home',
                icon: Icons.grid_view_rounded,
                isActive: currentIndex == 0,
                onTap: () => ref.read(navigationProvider.notifier).setIndex(0),
              ),
            ),
            Expanded(
              child: _NavItem(
                label: 'Discover',
                icon: Icons.explore_rounded,
                isActive: currentIndex == 1,
                onTap: () => ref.read(navigationProvider.notifier).setIndex(1),
              ),
            ),
            Expanded(
              child: _NavItem(
                label: 'Playlists',
                icon: Icons.playlist_play_rounded,
                isActive: currentIndex == 2,
                onTap: () => ref.read(navigationProvider.notifier).setIndex(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(24),
        splashColor: AetherColors.accentCyan.withValues(alpha: 0.15),
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: isActive ? AetherColors.accentCyan.withValues(alpha: 0.16) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isActive ? AetherColors.accentCyan.withValues(alpha: 0.4) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? AetherColors.accentCyan : Colors.white54,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white54,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

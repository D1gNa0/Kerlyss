import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/navigation_provider.dart';
import '../theme/aether_colors.dart';
import 'aether_glass.dart';
import 'vercel_hover_button.dart';

class AetherBottomNav extends ConsumerWidget {
  const AetherBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationProvider);

    final isMobile = Theme.of(context).platform == TargetPlatform.android || 
                    Theme.of(context).platform == TargetPlatform.iOS;

    return Container(
      height: 64,
      margin: EdgeInsets.fromLTRB(
        isMobile ? 12 : 40, 
        0, 
        isMobile ? 12 : 40, 
        isMobile ? 12 : 32
      ),
      child: AetherGlass(
        borderRadius: 32,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavIcon(
              tooltip: 'Home',
              icon: Icons.grid_view_rounded,
              isActive: currentIndex == 0,
              onTap: () => ref.read(navigationProvider.notifier).setIndex(0),
            ),
            _NavIcon(
              tooltip: 'Discover',
              icon: Icons.explore_rounded,
              isActive: currentIndex == 1,
              onTap: () => ref.read(navigationProvider.notifier).setIndex(1),
            ),
            _NavIcon(
              tooltip: 'Playlists',
              icon: Icons.playlist_play_rounded,
              isActive: currentIndex == 2,
              onTap: () => ref.read(navigationProvider.notifier).setIndex(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavIcon({required this.tooltip, required this.icon, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AetherIconButton(
      tooltip: tooltip,
      icon: icon,
      size: 24,
      buttonSize: 52,
      color: isActive ? Colors.white : Colors.white54,
      onPressed: onTap,
    );
  }
}

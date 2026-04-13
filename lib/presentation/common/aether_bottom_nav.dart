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

    return Container(
      height: 64,
      margin: const EdgeInsets.fromLTRB(40, 0, 40, 32),
      child: AetherGlass(
        borderRadius: 32,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavIcon(
              icon: Icons.grid_view_rounded,
              isActive: currentIndex == 0,
              onTap: () => ref.read(navigationProvider.notifier).setIndex(0),
            ),
            _NavIcon(
              icon: Icons.explore_rounded,
              isActive: currentIndex == 1,
              onTap: () => ref.read(navigationProvider.notifier).setIndex(1),
            ),
            _NavIcon(
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
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavIcon({required this.icon, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : AetherColors.textSecondary,
          size: 24,
        ),
      ),
    );
  }
}

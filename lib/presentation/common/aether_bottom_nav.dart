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
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? AetherColors.primaryAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.03),
          border: Border.all(
            color: isActive ? AetherColors.primaryAccent.withValues(alpha: 0.6) : Colors.transparent,
          ),
          boxShadow: isActive ? [
            BoxShadow(
              color: AetherColors.primaryAccent.withValues(alpha: 0.25),
              blurRadius: 12,
              spreadRadius: 0,
            )
          ] : [],
        ),
        child: Icon(
          icon,
          color: isActive ? AetherColors.primaryAccent : AetherColors.textSecondary,
          size: 22,
        ),
      ),
    );
  }
}

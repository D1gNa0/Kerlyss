import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/navigation_provider.dart';
import '../state/audio_provider.dart';
import 'home_view.dart';
import 'discovery_view.dart';
import '../common/aether_bottom_nav.dart';
import '../common/mini_player.dart';
import '../common/aether_title_bar.dart';
import '../theme/aether_colors.dart';

class MainShellView extends ConsumerWidget {
  const MainShellView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationProvider);
    final audioState = ref.watch(audioProvider);

    return Scaffold(
      backgroundColor: AetherColors.deepMatteBlack,
      body: Stack(
        children: [
          // Content Stack
          IndexedStack(
            index: currentIndex,
            children: const [
              HomeView(),
              DiscoveryView(),
              Center(child: Text('Profile Under Construction', style: TextStyle(color: Colors.white24))),
            ],
          ),

          // Custom Desktop Title Bar
          const AetherTitleBar(),

          // Global Player & Navigation
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // MiniPlayer (Only if a song is loaded)
                if (audioState.currentSong.id.isNotEmpty)
                  const MiniPlayer(),
                
                // Navigation Bar
                const AetherBottomNav(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

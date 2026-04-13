import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/navigation_provider.dart';
import '../state/audio_provider.dart';
import '../state/keyboard_shortcuts_provider.dart';
import 'home_view.dart';
import 'playlists_view.dart';
import 'discovery_view.dart';
import 'downloaded_songs_view.dart';

import '../common/aether_bottom_nav.dart';
import '../common/mini_player.dart';
import '../common/aether_title_bar.dart';
import '../theme/aether_colors.dart';

class MainShellView extends ConsumerStatefulWidget {
  const MainShellView({super.key});

  @override
  ConsumerState<MainShellView> createState() => _MainShellViewState();
}

class _MainShellViewState extends ConsumerState<MainShellView> {
  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }

    if (ref.read(keyboardShortcutsSuppressedProvider)) {
      return false;
    }

    final notifier = ref.read(audioProvider.notifier);
    final isControlPressed = HardwareKeyboard.instance.isControlPressed;

    if (event.logicalKey == LogicalKeyboardKey.space) {
      notifier.togglePlay();
      return true;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (isControlPressed) {
        notifier.next();
      } else {
        notifier.seekRelative(5);
      }
      return true;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (isControlPressed) {
        notifier.previous();
      } else {
        notifier.seekRelative(-5);
      }
      return true;
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);
    final audioState = ref.watch(audioProvider);

    return Scaffold(
      backgroundColor: AetherColors.deepMatteBlack,
      body: Stack(
        children: [
          // Content Stack
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: IndexedStack(
              index: currentIndex,
              children: [
                HomeView(),
                DiscoveryView(),
                PlaylistsView(),
              ],



            ),
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

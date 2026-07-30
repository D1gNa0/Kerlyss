import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/navigation_provider.dart';
import '../state/audio_provider.dart';
import '../state/keyboard_shortcuts_provider.dart';
import 'home_view.dart';
import 'playlists_view.dart';
import 'discovery_view.dart';

import '../common/aether_bottom_nav.dart';
import '../common/mini_player.dart';
import '../common/aether_title_bar.dart';
import '../theme/aether_colors.dart';
import '../state/download_state_provider.dart';
import '../../core/services/update_service.dart';

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
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService().checkForUpdates(context);
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);

    return Scaffold(
      backgroundColor: AetherColors.deepMatteBlack,
      body: Stack(
        children: [
          // Content Stack
          Padding(
            padding: EdgeInsets.only(
              top: !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS) ? 40 : 0,
              bottom: 140, // Ensure room for persistent MiniPlayer + Nav
            ),
            child: SafeArea(
              top: true,
              bottom: false,
              child: IndexedStack(
                index: currentIndex,
                children: const [
                  HomeView(),
                  DiscoveryView(),
                  PlaylistsView(),
                ],
              ),
            ),
          ),

          // Custom Desktop Title Bar
          const AetherTitleBar(),

          // Global Player & Navigation
          const Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              bottom: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bulk Progress Indicator
                  _BulkDownloadOverlay(),

                  // Global Persistent Player
                  MiniPlayer(),
                  
                  // Navigation Bar
                  AetherBottomNav(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulkDownloadOverlay extends ConsumerWidget {
  const _BulkDownloadOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(downloadStateProvider);
    if (!state.isBulkActive) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AetherColors.ultraDarkGray.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.downloading_rounded, color: AetherColors.primaryAccent, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SAVING PLAYLIST: ${state.bulkCompleted} OF ${state.bulkTotal} TRACKS',
                  style: const TextStyle(color: Colors.white, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${((state.bulkCompleted / (state.bulkTotal > 0 ? state.bulkTotal : 1)) * 100).toInt()}%',
                style: const TextStyle(color: AetherColors.primaryAccent, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: state.bulkTotal > 0 ? state.bulkCompleted / state.bulkTotal : 0,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(AetherColors.primaryAccent),
              minHeight: 2,
            ),
          ),
        ],
      ),
    );
  }
}

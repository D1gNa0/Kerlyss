import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/navigation_provider.dart';
import '../state/audio_provider.dart';
import '../state/audio_state.dart';
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
import 'download_components/download_queue_bottom_sheet.dart';

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

    ref.listen<AudioState>(audioProvider, (AudioState? previous, AudioState next) {
      if (next.status == PlaybackStatus.error && next.errorMessage != null && previous?.errorMessage != next.errorMessage) {
        final songTitle = next.currentSong.title.isNotEmpty ? '"${next.currentSong.title}"' : 'this track';
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AetherColors.ultraDarkGray,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: AetherColors.error, size: 22),
                SizedBox(width: 10),
                Text('PLAYBACK ERROR', style: TextStyle(color: Colors.white, fontSize: 13, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unable to play $songTitle:',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  next.errorMessage!,
                  style: const TextStyle(color: AetherColors.accentCyan, fontSize: 12),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please check your internet connection, or try playing another song.',
                  style: TextStyle(color: AetherColors.textSecondary, fontSize: 11, height: 1.4),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('DISMISS', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    });

    return PopScope(
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && currentIndex != 0) {
          ref.read(navigationProvider.notifier).setIndex(0);
        }
      },
      child: Scaffold(
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
                    // Global Download Progress Indicator
                    _DownloadProgressOverlay(),

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
      ),
    );
  }
}

class _DownloadProgressOverlay extends ConsumerWidget {
  const _DownloadProgressOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(downloadStateProvider);
    if (!state.isAnyDownloadActive) return const SizedBox.shrink();

    final activeSong = state.activeSong;
    final progress = state.activeSongProgress;
    final progressPct = (progress * 100).toInt();

    String titleText;
    if (state.isBulkActive) {
      final currentNum = state.bulkCompleted + 1;
      final totalNum = state.bulkTotal;
      titleText = 'DOWNLOADING PLAYLIST ($currentNum/$totalNum)${activeSong != null ? ': ${activeSong.title.toUpperCase()}' : ''}';
    } else if (activeSong != null) {
      titleText = 'DOWNLOADING: "${activeSong.title.toUpperCase()}"';
    } else {
      titleText = 'DOWNLOADING (${state.downloadingTrackIds.length} IN QUEUE)';
    }

    return GestureDetector(
      onTap: () => DownloadQueueBottomSheet.show(context),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AetherColors.ultraDarkGray.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AetherColors.primaryAccent.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.downloading_rounded, color: AetherColors.primaryAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titleText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  progress > 0 ? '$progressPct%' : '..',
                  style: const TextStyle(color: AetherColors.primaryAccent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white54, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress > 0 ? progress : null,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(AetherColors.primaryAccent),
                minHeight: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

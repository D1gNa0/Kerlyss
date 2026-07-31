import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/audio_provider.dart';
import '../state/audio_state.dart';
import '../common/aether_title_bar.dart';
import '../theme/aether_colors.dart';
import '../common/aether_pulse_visualizer.dart';
import '../common/aether_network_image.dart';
import 'package:kerlyss/l10n/app_localizations.dart';
import 'queue_view.dart';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/foundation.dart';

class FullPlayerView extends ConsumerWidget {
  const FullPlayerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioProvider);
    final currentSong = audioState.currentSong;
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final durationMs = currentSong.duration.inMilliseconds.toDouble();
    final sliderMax = durationMs > 0 ? durationMs : 1000.0;
    final sliderValue = audioState.position.inMilliseconds.toDouble().clamp(0.0, sliderMax);


    return Scaffold(
      backgroundColor: AetherColors.deepMatteBlack,
      body: Stack(
        children: [
          // Dynamic Background Blur
          Positioned.fill(
            child: Container(
              color: AetherColors.ultraDarkGray,
              child: Opacity(
                opacity: 0.5,
                child: currentSong.artworkUrl != null
                    ? AetherNetworkImage(
                        url: currentSong.artworkUrl!,
                        fit: BoxFit.cover,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(color: Colors.black.withValues(alpha: 0.3)),
            ),
          ),

          // Custom Desktop Title Bar (drag-to-move works in full player too)
          const AetherTitleBar(showTitle: true),

          // Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
                      ),
                      Text(
                        l10n.appTitle,
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 12),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _showSleepTimerDialog(context, ref, audioState),
                            icon: Icon(
                              Icons.timer_outlined,
                              color: audioState.sleepTimerRemaining != null ? Colors.amberAccent : Colors.white70,
                              size: 22,
                            ),
                            tooltip: audioState.sleepTimerRemaining != null
                                ? 'Sleep timer: ${audioState.sleepTimerRemaining!.inMinutes}m'
                                : 'Set Sleep Timer',
                          ),
                          IconButton(
                            onPressed: () {
                              showGeneralDialog(
                                context: context,
                                barrierDismissible: true,
                                barrierLabel: 'Queue',
                                barrierColor: Colors.black54,
                                pageBuilder: (context, anim, secondAnim) {
                                  return Align(
                                    alignment: Alignment.centerRight,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: SlideTransition(
                                        position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(anim),
                                        child: QueueView(onClose: () => Navigator.pop(context)),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.queue_music_rounded, size: 24),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Aether Pulse Visualizer (Behind Album Art)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (audioState.status == PlaybackStatus.playing)
                        const RepaintBoundary(
                          child: AetherPulseVisualizer(size: 300),
                        ),
                      
                      // Album Art — capped at 300 to prevent overflow on 800px desktop
                      Hero(
                        tag: 'album_art_${currentSong.id}',
                        child: Center(
                          child: Container(
                            width: screenWidth * 0.55 > 300 ? 300 : screenWidth * 0.55,
                            height: screenWidth * 0.55 > 300 ? 300 : screenWidth * 0.55,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  blurRadius: 50,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 20),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: AetherNetworkImage(
                                url: currentSong.artworkUrl ?? '',
                                width: double.infinity,
                                height: double.infinity,
                                borderRadius: 24,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Song Info Refined
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        currentSong.title.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentSong.artist.toUpperCase(),
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontSize: 11,
                              color: AetherColors.textSecondary,
                            ),
                      ),
                      if (currentSong.bpm != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white.withValues(alpha: 0.03),
                            border: Border.all(
                              color: AetherColors.accentCyan.withValues(alpha: 0.4)
                            ),
                          ),
                          child: Text(
                            '${currentSong.bpm} BPM',
                            style: const TextStyle(
                              color: AetherColors.accentCyan,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Playback Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // STUB: shuffle not implemented
                      Tooltip(
                        message: l10n.stubNotImplemented,
                        child: Stack(children: [
                          const Icon(Icons.shuffle_rounded, color: AetherColors.textSecondary, size: 20),
                          Positioned(top: 0, right: 0, child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
                        ]),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded, size: 32, color: Colors.white),
                        onPressed: () => ref.read(audioProvider.notifier).previous(),
                        tooltip: l10n.previousShortcut,
                      ),
                      const SizedBox(width: 8),
                      // Skip Back 5s
                      Tooltip(
                        message: l10n.back5s,
                        child: IconButton(
                          icon: const Icon(Icons.replay_5_rounded, size: 28, color: Colors.white70),
                          onPressed: () => ref.read(audioProvider.notifier).seekRelative(-5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: audioState.status == PlaybackStatus.error
                            ? (audioState.errorMessage ?? 'Playback error - tap to retry')
                            : l10n.playPause,
                        child: GestureDetector(
                          onTap: () {
                            if (audioState.status == PlaybackStatus.error) {
                              ref.read(audioProvider.notifier).togglePlay();
                            } else {
                              ref.read(audioProvider.notifier).togglePlay();
                            }
                          },
                          child: Container(
                            width: 68,
                            height: 68,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: audioState.status == PlaybackStatus.error ? Colors.red : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: audioState.status == PlaybackStatus.error
                                ? const Icon(
                                    Icons.error_outline_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  )
                                : Padding(
                                    padding: EdgeInsets.only(
                                      left: audioState.status == PlaybackStatus.playing ? 0 : 4,
                                    ),
                                    child: audioState.status == PlaybackStatus.loading || audioState.status == PlaybackStatus.buffering
                                        ? SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: audioState.status == PlaybackStatus.error ? Colors.white : Colors.black,
                                              strokeWidth: 3,
                                            ),
                                          )
                                        : Icon(
                                            audioState.status == PlaybackStatus.playing
                                                ? Icons.pause_rounded
                                                : Icons.play_arrow_rounded,
                                            color: Colors.black,
                                            size: 40,
                                          ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Skip Forward 5s
                      Tooltip(
                        message: l10n.forward5s,
                        child: IconButton(
                          icon: const Icon(Icons.forward_5_rounded, size: 28, color: Colors.white70),
                          onPressed: () => ref.read(audioProvider.notifier).seekRelative(5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, size: 32, color: Colors.white),
                        onPressed: () => ref.read(audioProvider.notifier).next(),
                        tooltip: l10n.nextShortcut,
                      ),
                      // STUB: repeat not implemented
                      Tooltip(
                        message: l10n.stubNotImplemented,
                        child: Stack(children: [
                          const Icon(Icons.repeat_rounded, color: AetherColors.textSecondary, size: 20),
                          Positioned(top: 0, right: 0, child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Horizon Progress Bar (Thin line at the bottom)
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(audioState.position),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                            ),
                            Text(
                              _formatDuration(currentSong.duration),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 1.5, // Ultra-thin Spotify style
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white.withValues(alpha: 0.05),
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: sliderValue,
                          max: sliderMax,
                          onChanged: (value) {
                            if (durationMs <= 0) {
                              return;
                            }
                            ref.read(audioProvider.notifier).seek(Duration(milliseconds: value.toInt()));
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Windows Volume Control
                  if (!kIsWeb && Platform.isWindows)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.volume_up_rounded, color: AetherColors.textSecondary, size: 16),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 1.5,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                activeTrackColor: Colors.white54,
                                inactiveTrackColor: Colors.white.withValues(alpha: 0.05),
                                thumbColor: Colors.white70,
                              ),
                              child: Slider(
                                value: audioState.volume,
                                onChanged: (v) => ref.read(audioProvider.notifier).setVolume(v),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    void _showSleepTimerDialog(BuildContext context, WidgetRef ref, AudioState audioState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AetherColors.ultraDarkGray,
        title: const Text('SLEEP TIMER', style: TextStyle(color: Colors.white, fontSize: 13, letterSpacing: 2)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (audioState.sleepTimerRemaining != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Active: ${audioState.sleepTimerRemaining!.inMinutes}m remaining',
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 12),
                ),
              ),
            ListTile(
              title: const Text('15 Minutes', style: TextStyle(color: Colors.white, fontSize: 14)),
              onTap: () {
                ref.read(audioProvider.notifier).setSleepTimer(const Duration(minutes: 15));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('30 Minutes', style: TextStyle(color: Colors.white, fontSize: 14)),
              onTap: () {
                ref.read(audioProvider.notifier).setSleepTimer(const Duration(minutes: 30));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('45 Minutes', style: TextStyle(color: Colors.white, fontSize: 14)),
              onTap: () {
                ref.read(audioProvider.notifier).setSleepTimer(const Duration(minutes: 45));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('60 Minutes', style: TextStyle(color: Colors.white, fontSize: 14)),
              onTap: () {
                ref.read(audioProvider.notifier).setSleepTimer(const Duration(minutes: 60));
                Navigator.pop(context);
              },
            ),
            if (audioState.sleepTimerRemaining != null)
              ListTile(
                title: const Text('Turn Off Timer', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                onTap: () {
                  ref.read(audioProvider.notifier).setSleepTimer(null);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
          ),
        ],
      ),
    );
  }
}

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

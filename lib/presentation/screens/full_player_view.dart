import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/audio_provider.dart';
import '../state/audio_state.dart';
import '../common/aether_glass.dart';
import '../common/aether_title_bar.dart';
import '../theme/aether_colors.dart';
import '../common/aether_pulse_visualizer.dart';
import 'dart:ui';

class FullPlayerView extends ConsumerWidget {
  const FullPlayerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioProvider);
    final currentSong = audioState.currentSong;
    final screenWidth = MediaQuery.of(context).size.width;
    final durationSeconds = currentSong.duration.inSeconds.toDouble();
    final sliderMax = durationSeconds > 0 ? durationSeconds : 1.0;
    final sliderValue = audioState.position.inSeconds.toDouble().clamp(0.0, sliderMax);

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
                    ? Image.network(currentSong.artworkUrl!, fit: BoxFit.cover)
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(color: Colors.black.withOpacity(0.3)),
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
                        'KERLYSS',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 12),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.more_horiz_rounded, size: 24),
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
                                  color: Colors.black.withOpacity(0.6),
                                  blurRadius: 50,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 20),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: currentSong.artworkUrl != null
                                  ? Image.network(currentSong.artworkUrl!, fit: BoxFit.cover)
                                  : Container(
                                      color: AetherColors.ultraDarkGray,
                                      child: const Icon(Icons.music_note, size: 60),
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
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Playback Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // STUB: shuffle not implemented
                      Tooltip(
                        message: 'STUB — Not Implemented',
                        child: Stack(children: [
                          const Icon(Icons.shuffle_rounded, color: AetherColors.textSecondary, size: 20),
                          Positioned(top: 0, right: 0, child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
                        ]),
                      ),
                      // STUB: skip previous not implemented
                      Tooltip(
                        message: 'STUB — Not Implemented',
                        child: Stack(children: [
                          const Icon(Icons.skip_previous_rounded, size: 32),
                          Positioned(top: 0, right: 0, child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      // Skip Back 5s
                      IconButton(
                        icon: const Icon(Icons.replay_5_rounded, size: 28, color: Colors.white70),
                        onPressed: () => ref.read(audioProvider.notifier).seekRelative(-5),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => ref.read(audioProvider.notifier).togglePlay(),
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.2),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: Icon(
                            audioState.status == PlaybackStatus.playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.black,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Skip Forward 5s
                      IconButton(
                        icon: const Icon(Icons.forward_5_rounded, size: 28, color: Colors.white70),
                        onPressed: () => ref.read(audioProvider.notifier).seekRelative(5),
                      ),
                      const SizedBox(width: 8),
                      // STUB: skip next not implemented
                      Tooltip(
                        message: 'STUB — Not Implemented',
                        child: Stack(children: [
                          const Icon(Icons.skip_next_rounded, size: 32),
                          Positioned(top: 0, right: 0, child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
                        ]),
                      ),
                      // STUB: repeat not implemented
                      Tooltip(
                        message: 'STUB — Not Implemented',
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
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white.withOpacity(0.1),
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: sliderValue,
                          max: sliderMax,
                          onChanged: (value) {
                            if (durationSeconds <= 0) {
                              return;
                            }
                            ref.read(audioProvider.notifier).seek(Duration(seconds: value.toInt()));
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/audio_provider.dart';
import '../theme/aether_colors.dart';
import 'aether_glass.dart';
import 'vercel_hover_button.dart';

class AetherVolumeButton extends ConsumerStatefulWidget {
  const AetherVolumeButton({super.key});

  @override
  ConsumerState<AetherVolumeButton> createState() => _AetherVolumeButtonState();
}

class _AetherVolumeButtonState extends ConsumerState<AetherVolumeButton> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  Timer? _dismissTimer;
  double _lastNonZeroVolume = 0.8;

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _resetDismissTimer() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _removeOverlay();
      }
    });
  }

  void _toggleOverlay() {
    if (_overlayEntry != null) {
      _removeOverlay();
      return;
    }

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Tap outside to dismiss
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeOverlay,
                child: const SizedBox.expand(),
              ),
            ),
            // Floating Volume Slider Popover
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(-80, -64),
              child: Material(
                color: Colors.transparent,
                child: MouseRegion(
                  onEnter: (_) => _dismissTimer?.cancel(),
                  onExit: (_) => _resetDismissTimer(),
                  child: Container(
                    width: 220,
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: AetherGlass(
                      borderRadius: 16,
                      opacity: 0.18,
                      child: Consumer(
                        builder: (context, ref, child) {
                          final audioState = ref.watch(audioProvider);
                          final volume = audioState.volume;

                          return Row(
                            children: [
                              // Mute/Unmute Quick Toggle
                              VercelHoverButton(
                                onTap: () {
                                  _resetDismissTimer();
                                  if (volume > 0) {
                                    _lastNonZeroVolume = volume;
                                    ref.read(audioProvider.notifier).setVolume(0.0);
                                  } else {
                                    ref.read(audioProvider.notifier).setVolume(_lastNonZeroVolume);
                                  }
                                },
                                borderRadius: 10,
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  volume == 0.0
                                      ? Icons.volume_off_rounded
                                      : (volume < 0.5 ? Icons.volume_down_rounded : Icons.volume_up_rounded),
                                  color: volume == 0.0 ? AetherColors.error : Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                    activeTrackColor: Colors.white,
                                    inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
                                    thumbColor: Colors.white,
                                  ),
                                  child: Slider(
                                    value: volume.clamp(0.0, 1.0),
                                    onChanged: (val) {
                                      _resetDismissTimer();
                                      if (val > 0) _lastNonZeroVolume = val;
                                      ref.read(audioProvider.notifier).setVolume(val);
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 36,
                                child: Text(
                                  '${(volume * 100).round()}%',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_overlayEntry!);
    _resetDismissTimer();
  }

  void _handlePointerScroll(PointerScrollEvent event) {
    final audioState = ref.read(audioProvider);
    final currentVolume = audioState.volume;
    final delta = event.scrollDelta.dy > 0 ? -0.05 : 0.05;
    final newVolume = (currentVolume + delta).clamp(0.0, 1.0);

    if (newVolume > 0) {
      _lastNonZeroVolume = newVolume;
    }
    ref.read(audioProvider.notifier).setVolume(newVolume);

    if (_overlayEntry == null) {
      _toggleOverlay();
    } else {
      _resetDismissTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioProvider);
    final volume = audioState.volume;

    IconData iconData;
    Color iconColor;

    if (volume == 0.0) {
      iconData = Icons.volume_off_rounded;
      iconColor = AetherColors.error;
    } else if (volume < 0.5) {
      iconData = Icons.volume_down_rounded;
      iconColor = Colors.white70;
    } else {
      iconData = Icons.volume_up_rounded;
      iconColor = Colors.white;
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: Listener(
        onPointerSignal: (pointerEvent) {
          if (pointerEvent is PointerScrollEvent) {
            _handlePointerScroll(pointerEvent);
          }
        },
        child: Tooltip(
          message: 'Volume (${(volume * 100).round()}%) — Tap for slider or scroll wheel',
          child: VercelHoverButton(
            onTap: _toggleOverlay,
            borderRadius: 12,
            padding: const EdgeInsets.all(8),
            child: Icon(
              iconData,
              color: iconColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

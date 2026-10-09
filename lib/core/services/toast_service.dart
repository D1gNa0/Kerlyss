import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../presentation/theme/aether_colors.dart';

/// Lightweight, NON-BLOCKING toast.
///
/// The old implementation used a floating [SnackBar]. A SnackBar is a real
/// widget that absorbs pointer events, and because the mini player / bottom nav
/// are placed manually inside a [Stack] (not as Scaffold bottom bars) the
/// SnackBar was drawn right on top of them and swallowed taps.
///
/// This version lives in the root [Overlay], is wrapped in [IgnorePointer]
/// (taps pass straight through it) and is shown at the TOP of the screen where
/// there are no player controls. The public API is unchanged, so every existing
/// `ToastService.show(...)` call keeps working.
class ToastService {
  ToastService._();

  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!context.mounted) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final bool isError =
        backgroundColor == Colors.redAccent || backgroundColor == AetherColors.error;
    final bool isWarning =
        backgroundColor == Colors.amber || backgroundColor == AetherColors.warning;

    final IconData leadingIcon = icon ??
        (isError
            ? Icons.error_outline_rounded
            : isWarning
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline_rounded);

    final Color accentColor = isError
        ? Colors.redAccent
        : isWarning
            ? Colors.amberAccent
            : AetherColors.accentCyan;

    // Replace any toast that is still visible.
    _dismiss();

    final entry = OverlayEntry(
      builder: (_) => _ToastOverlay(
        message: message,
        icon: leadingIcon,
        accentColor: accentColor,
        backgroundColor: backgroundColor ?? AetherColors.ultraDarkGray,
        visibleFor: duration,
      ),
    );
    _entry = entry;
    overlay.insert(entry);

    _timer = Timer(duration + const Duration(milliseconds: 300), () {
      if (identical(_entry, entry)) _dismiss();
    });
  }

  static void _dismiss() {
    _timer?.cancel();
    _timer = null;
    final entry = _entry;
    _entry = null;
    if (entry != null) {
      try {
        entry.remove();
      } catch (_) {
        // Overlay may already be gone (e.g. app closing). Safe to ignore.
      }
    }
  }
}

class _ToastOverlay extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color accentColor;
  final Color backgroundColor;
  final Duration visibleFor;

  const _ToastOverlay({
    required this.message,
    required this.icon,
    required this.accentColor,
    required this.backgroundColor,
    required this.visibleFor,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _fadeOutTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..forward();

    final fadeOutAt = widget.visibleFor - const Duration(milliseconds: 220);
    _fadeOutTimer = Timer(
      fadeOutAt.isNegative ? Duration.zero : fadeOutAt,
      () {
        if (mounted) _controller.reverse();
      },
    );
  }

  @override
  void dispose() {
    _fadeOutTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bool hasDesktopTitleBar =
        !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    final double top = media.padding.top + (hasDesktopTitleBar ? 52 : 12);

    return Positioned(
      top: top,
      left: 20,
      right: 20,
      // IgnorePointer => the toast can never block a tap.
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.topCenter,
          child: FadeTransition(
            opacity: _controller,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.3),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: widget.backgroundColor.withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: widget.accentColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: widget.accentColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(widget.icon, color: widget.accentColor, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  widget.message,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.3,
                                    decoration: TextDecoration.none,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

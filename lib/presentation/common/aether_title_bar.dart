import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../theme/aether_colors.dart';

/// A platform-aware custom title bar with drag-to-move and window controls.
/// Inject this as an overlay anywhere on Desktop routes.
class AetherTitleBar extends StatelessWidget {
  final bool showTitle;
  const AetherTitleBar({super.key, this.showTitle = false});

  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  @override
  Widget build(BuildContext context) {
    if (!isDesktop) return const SizedBox.shrink();

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 36,
        child: DragToMoveArea(
          child: Row(
            children: [
              if (showTitle)
                const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Text(
                    'KERLYSS',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      letterSpacing: 4,
                    ),
                  ),
                ),
              const Spacer(),
              // Minimize
              _WindowButton(
                icon: Icons.horizontal_rule_rounded,
                onTap: () => windowManager.minimize(),
              ),
              // Maximize / Restore
              _MaximizeButton(),
              // Close
              _WindowButton(
                icon: Icons.close_rounded,
                onTap: () => windowManager.close(),
                hoverColor: Colors.red.withOpacity(0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? hoverColor;

  const _WindowButton({required this.icon, required this.onTap, this.hoverColor});

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 46,
          height: 36,
          color: _hovered
              ? (widget.hoverColor ?? Colors.white.withOpacity(0.1))
              : Colors.transparent,
          child: Icon(
            widget.icon,
            size: 16,
            color: _hovered ? Colors.white : Colors.white54,
          ),
        ),
      ),
    );
  }
}

class _MaximizeButton extends StatefulWidget {
  @override
  State<_MaximizeButton> createState() => _MaximizeButtonState();
}

class _MaximizeButtonState extends State<_MaximizeButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () async {
          final isMaximized = await windowManager.isMaximized();
          if (isMaximized) {
            windowManager.unmaximize();
          } else {
            windowManager.maximize();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 46,
          height: 36,
          color: _hovered ? Colors.white.withOpacity(0.1) : Colors.transparent,
          child: Icon(
            Icons.crop_square_rounded,
            size: 14,
            color: _hovered ? Colors.white : Colors.white54,
          ),
        ),
      ),
    );
  }
}

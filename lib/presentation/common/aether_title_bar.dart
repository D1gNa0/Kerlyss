import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// A platform-aware custom title bar with drag-to-move and window controls.
/// Inject this as a Positioned overlay in any Stack/Scaffold body.
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
      child: Container(
        height: 40,
        // Always-visible dark strip — guarantees buttons render regardless of background
        color: const Color(0xCC0A0A0A),
        child: Row(
          children: [
            // Drag area — takes all space except the buttons
            Expanded(
              child: DragToMoveArea(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  padding: const EdgeInsets.only(left: 16),
                  alignment: Alignment.centerLeft,
                  child: showTitle
                      ? const Text(
                          'KERLYSS',
                          style: TextStyle(
                            color: Colors.white30,
                            fontSize: 10,
                            letterSpacing: 4,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),


            // Window control buttons — outside DragToMoveArea so clicks register
            _WinBtn(
              icon: Icons.remove_rounded,
              tooltip: 'Minimize',
              onTap: () => windowManager.minimize(),
            ),
            _WinBtn(
              icon: Icons.crop_square_outlined,
              tooltip: 'Maximize',
              onTap: () async {
                if (await windowManager.isMaximized()) {
                  windowManager.unmaximize();
                } else {
                  windowManager.maximize();
                }
              },
            ),
            _WinBtn(
              icon: Icons.close_rounded,
              tooltip: 'Close',
              onTap: () => windowManager.close(),
              isClose: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _WinBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isClose;

  const _WinBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isClose = false,
  });

  @override
  State<_WinBtn> createState() => _WinBtnState();
}

class _WinBtnState extends State<_WinBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hoverBg = widget.isClose
        ? const Color(0xFFE81123) // Classic Windows red
        : Colors.white.withValues(alpha: 0.12);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: widget.tooltip,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 46,
            height: 40,
            color: _hovered ? hoverBg : Colors.transparent,
            alignment: Alignment.center,
            child: Icon(
              widget.icon,
              size: 18,
              color: _hovered ? Colors.white : Colors.white60,
            ),
          ),
        ),
      ),
    );
  }
}

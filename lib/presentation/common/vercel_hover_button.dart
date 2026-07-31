import 'package:flutter/material.dart';
import '../theme/aether_colors.dart';

/// A Vercel.com inspired hover button/card component.
/// Tracks cursor coordinates in real-time to render a soft, wide ambient backlight
/// coming from behind the glass tile right where the user is hovering.
class VercelHoverButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color accentColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const VercelHoverButton({
    super.key,
    required this.child,
    this.onTap,
    this.accentColor = Colors.white,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  State<VercelHoverButton> createState() => _VercelHoverButtonState();
}

class _VercelHoverButtonState extends State<VercelHoverButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  Offset _hoverOffset = Offset.zero;
  Size _widgetSize = Size.zero;

  void _updateHoverOffset(PointerEvent details) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      setState(() {
        _hoverOffset = details.localPosition;
        _widgetSize = box.size;
      });
    }
  }

  Alignment _calculateGradientAlignment() {
    if (_widgetSize.width == 0 || _widgetSize.height == 0) {
      return Alignment.center;
    }
    final double x = (2 * (_hoverOffset.dx / _widgetSize.width)) - 1;
    final double y = (2 * (_hoverOffset.dy / _widgetSize.height)) - 1;
    return Alignment(x.clamp(-1.0, 1.0), y.clamp(-1.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _isHovered || _isPressed;
    final lightCenter = _calculateGradientAlignment();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (e) {
        _updateHoverOffset(e);
        setState(() => _isHovered = true);
      },
      onHover: _updateHoverOffset,
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          padding: widget.padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: isActive
                  ? widget.accentColor.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.08),
              width: isActive ? 1.5 : 1.0,
            ),
            gradient: RadialGradient(
              center: lightCenter,
              radius: 2.2,
              colors: isActive
                  ? [
                      widget.accentColor.withValues(alpha: 0.12),
                      widget.accentColor.withValues(alpha: 0.03),
                      AetherColors.ultraDarkGray.withValues(alpha: 0.7),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.04),
                      Colors.white.withValues(alpha: 0.01),
                      AetherColors.ultraDarkGray.withValues(alpha: 0.5),
                    ],
              stops: const [0.0, 0.45, 1.0],
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.15),
                      blurRadius: 24,
                      spreadRadius: -2,
                    ),
                  ]
                : [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

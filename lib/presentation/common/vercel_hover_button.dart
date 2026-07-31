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
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (e) {
        _updateHoverOffset(e);
        setState(() => _isHovered = true);
      },
      onHover: _updateHoverOffset,
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: widget.onTap != null ? (_) => setState(() => _isPressed = false) : null,
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
                      widget.accentColor.withValues(alpha: 0.15),
                      widget.accentColor.withValues(alpha: 0.04),
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

/// Unified minimalist control icon button matching VercelHoverButton design.
class AetherIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final String? tooltip;
  final double size;
  final double buttonSize;

  const AetherIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.tooltip,
    this.size = 20,
    this.buttonSize = 40,
  });

  @override
  State<AetherIconButton> createState() => _AetherIconButtonState();
}

class _AetherIconButtonState extends State<AetherIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final defaultColor = widget.color ?? (enabled ? Colors.white70 : Colors.white24);
    final activeColor = enabled ? (widget.color ?? Colors.white) : Colors.white24;

    Widget button = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = enabled),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.buttonSize,
          height: widget.buttonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isHovered ? Colors.white.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.03),
            border: Border.all(
              color: _isHovered ? Colors.white.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.08),
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: _isHovered ? [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.15),
                blurRadius: 16,
                spreadRadius: -1,
              )
            ] : [],
          ),
          child: Center(
            child: Icon(
              widget.icon,
              size: widget.size,
              color: _isHovered ? activeColor : defaultColor,
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }

    return button;
  }
}

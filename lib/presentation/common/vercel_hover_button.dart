import 'package:flutter/material.dart';
import '../theme/aether_colors.dart';

/// A clean, modern Vercel-style hover card component.
/// Provides instant, uniform surface highlight and hairline border illumination on hover
/// without any mouse-following movement.
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

  @override
  Widget build(BuildContext context) {
    final isActive = _isHovered || _isPressed;

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
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
                  ? widget.accentColor.withValues(alpha: 0.28)
                  : Colors.white.withValues(alpha: 0.06),
              width: isActive ? 1.5 : 1.0,
            ),
            color: isActive
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.02),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.08),
                      blurRadius: 16,
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

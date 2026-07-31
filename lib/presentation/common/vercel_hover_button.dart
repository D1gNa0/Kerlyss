import 'package:flutter/material.dart';
import '../theme/aether_colors.dart';

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
    this.accentColor = AetherColors.primaryAccent,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: isActive
                  ? widget.accentColor.withValues(alpha: 0.6)
                  : AetherColors.glassBorder,
              width: isActive ? 1.5 : 1.0,
            ),
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: isActive
                  ? [
                      widget.accentColor.withValues(alpha: 0.25),
                      widget.accentColor.withValues(alpha: 0.08),
                      AetherColors.ultraDarkGray.withValues(alpha: 0.8),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.03),
                      AetherColors.ultraDarkGray.withValues(alpha: 0.6),
                    ],
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.2),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/aether_colors.dart';

class GlowEdgeContainer extends StatelessWidget {
  final Widget child;
  final bool isGlowing;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? glowColor;

  const GlowEdgeContainer({
    super.key,
    required this.child,
    this.isGlowing = true,
    this.borderRadius = 16.0,
    this.padding,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeGlowColor = glowColor ?? AetherColors.primaryAccent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isGlowing
            ? [
                BoxShadow(
                  color: activeGlowColor.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Container(
        decoration: isGlowing
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                gradient: LinearGradient(
                  colors: [
                    activeGlowColor.withValues(alpha: 0.8),
                    AetherColors.secondaryAccent.withValues(alpha: 0.4),
                    Colors.white.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              )
            : BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: AetherColors.glassBorder, width: 1.0),
              ),
        padding: isGlowing ? const EdgeInsets.all(1.0) : EdgeInsets.zero,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AetherColors.ultraDarkGray.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(isGlowing ? borderRadius - 1.0 : borderRadius),
          ),
          child: child,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../theme/aether_colors.dart';

class AetherGlass extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;

  const AetherGlass({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 15.0, // Thinner blur for classic feel
    this.opacity = 0.08, // Very subtle glass
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GlassmorphicContainer(
        width: double.infinity,
        height: double.infinity,
        borderRadius: borderRadius,
        blur: blur,
        alignment: Alignment.center,
        border: 0.5, // Ultra-thin border
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AetherColors.glassWhite.withOpacity(opacity),
            AetherColors.glassWhite.withOpacity(opacity * 0.2),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AetherColors.glassBorder.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}

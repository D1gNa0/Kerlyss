import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../theme/aether_colors.dart';

class AetherGlass extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const AetherGlass({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 15.0,
    this.opacity = 0.08,
    this.padding,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Safe size fallback for unconstrained layouts (ListView/Column)
        final w = width ?? (constraints.hasBoundedWidth ? double.infinity : 340.0);
        final h = height ?? (constraints.hasBoundedHeight ? double.infinity : 180.0);

        return RepaintBoundary(
          child: GlassmorphicContainer(
            width: w,
            height: h,
            borderRadius: borderRadius,
            blur: blur,
            alignment: Alignment.center,
            border: 0.5,
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
      },
    );
  }
}

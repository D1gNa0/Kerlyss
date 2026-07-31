import 'dart:ui';
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
    if (width != null || height != null) {
      return RepaintBoundary(
        child: GlassmorphicContainer(
          width: width ?? double.infinity,
          height: height ?? double.infinity,
          borderRadius: borderRadius,
          blur: blur,
          alignment: Alignment.center,
          border: 0.5,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AetherColors.glassWhite.withValues(alpha: opacity),
              AetherColors.glassWhite.withValues(alpha: opacity * 0.2),
            ],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AetherColors.glassBorder.withValues(alpha: 0.1),
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

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: AetherColors.glassBorder.withValues(alpha: 0.1),
                width: 0.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AetherColors.glassWhite.withValues(alpha: opacity),
                  AetherColors.glassWhite.withValues(alpha: opacity * 0.2),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

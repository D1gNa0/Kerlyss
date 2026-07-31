import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/aether_colors.dart';

class AmbientLightCanvas extends StatefulWidget {
  final Widget child;

  const AmbientLightCanvas({
    super.key,
    required this.child,
  });

  @override
  State<AmbientLightCanvas> createState() => _AmbientLightCanvasState();
}

class _AmbientLightCanvasState extends State<AmbientLightCanvas> {
  Offset? _pointerOffset;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (PointerHoverEvent event) {
        setState(() {
          _pointerOffset = event.localPosition;
        });
      },
      onExit: (_) {
        setState(() {
          _pointerOffset = null;
        });
      },
      child: Stack(
        children: [
          widget.child,
          if (_pointerOffset != null)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _LightAuraPainter(_pointerOffset!),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LightAuraPainter extends CustomPainter {
  final Offset pointerOffset;

  _LightAuraPainter(this.pointerOffset);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AetherColors.primaryAccent.withValues(alpha: 0.08),
          AetherColors.primaryAccent.withValues(alpha: 0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromCircle(center: pointerOffset, radius: 150),
      );

    canvas.drawCircle(pointerOffset, 150, paint);
  }

  @override
  bool shouldRepaint(covariant _LightAuraPainter oldDelegate) {
    return oldDelegate.pointerOffset != pointerOffset;
  }
}

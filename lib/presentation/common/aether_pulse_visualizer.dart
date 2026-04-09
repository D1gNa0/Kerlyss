import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/audio_provider.dart';
import '../theme/aether_colors.dart';
import 'dart:math' as math;
import 'dart:developer';

class AetherPulseVisualizer extends ConsumerStatefulWidget {
  final double size;
  const AetherPulseVisualizer({super.key, this.size = 300});

  @override
  ConsumerState<AetherPulseVisualizer> createState() => _AetherPulseVisualizerState();
}

class _AetherPulseVisualizerState extends ConsumerState<AetherPulseVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  List<double> _bands = List.generate(16, (_) => 0.0);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to frequency data stream from audioProvider
    final frequencyStream = ref.watch(audioProvider.notifier).frequencyStream;

    return StreamBuilder<List<double>>(
      stream: frequencyStream,
      initialData: _bands,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _bands = snapshot.data!;
        }

        return RepaintBoundary(
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: AetherPulsePainter(
              bands: _bands,
              animationValue: _pulseController.value,
              primaryColor: AetherColors.primaryAccent,
              secondaryColor: AetherColors.secondaryAccent,
            ),
          ),
        );
      },
    );
  }
}

class AetherPulsePainter extends CustomPainter {
  final List<double> bands;
  final double animationValue;
  final Color primaryColor;
  final Color secondaryColor;

  AetherPulsePainter({
    required this.bands,
    required this.animationValue,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Timeline.startSync('AetherPulse:Paint');
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2.5;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw 3 layered aether rings
    for (int i = 0; i < 3; i++) {
      final double ringOffset = (animationValue + (i * 0.33)) % 1.0;
      final double opacity = (1.0 - ringOffset) * 0.4; // 10% - 40% range
      
      final double bassBoost = bands.take(4).reduce((a, b) => a + b) / 4.0;
      final double targetRadius = baseRadius + (ringOffset * 60) + (bassBoost * 20);

      paint.color = primaryColor.withOpacity(opacity.clamp(0.1, 0.4));
      paint.strokeWidth = 2.0 + (bassBoost * 4);

      canvas.drawCircle(center, targetRadius, paint);

      _drawFrequencyWave(canvas, center, targetRadius, opacity);
    }
    Timeline.finishSync();
  }

  void _drawFrequencyWave(Canvas canvas, Offset center, double radius, double opacity) {
    final Path wavePath = Path();
    final int points = bands.length;
    final double angleStep = (2 * math.pi) / points;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    paint.shader = LinearGradient(
      colors: [primaryColor.withOpacity(opacity), secondaryColor.withOpacity(opacity)],
    ).createShader(Rect.fromCircle(center: center, radius: radius + 20));

    for (int i = 0; i <= points; i++) {
      final double angle = i * angleStep;
      final double bandValue = bands[i % points];
      final double dynamicRadius = radius + (bandValue * 15);
      
      final double x = center.dx + math.cos(angle) * dynamicRadius;
      final double y = center.dy + math.sin(angle) * dynamicRadius;

      if (i == 0) {
        wavePath.moveTo(x, y);
      } else {
        wavePath.lineTo(x, y);
      }
    }
    canvas.drawPath(wavePath, paint);
  }

  @override
  bool shouldRepaint(covariant AetherPulsePainter oldDelegate) {
    return true; // Frequency data updates every 50ms, keep it fluid
  }
}

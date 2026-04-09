import 'package:flutter/material.dart';
import '../theme/aether_colors.dart';
import 'aether_pulse_visualizer.dart';

class AetherLoadingPulse extends StatefulWidget {
  final VoidCallback onCancel;
  const AetherLoadingPulse({super.key, required this.onCancel});

  @override
  State<AetherLoadingPulse> createState() => _AetherLoadingPulseState();
}

class _AetherLoadingPulseState extends State<AetherLoadingPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Reuse AetherPulsePainter logic for a steady loading pulse
          SizedBox(
            width: 250,
            height: 250,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: AetherPulsePainter(
                    bands: List.generate(16, (index) => 0.2 + (index % 3) * 0.1), // Steady pattern
                    animationValue: _controller.value,
                    primaryColor: AetherColors.primaryAccent,
                    secondaryColor: AetherColors.secondaryAccent,
                  ),
                );
              },
            ),
          ),
          
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'RESOLVING...',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontSize: 12,
                      letterSpacing: 4,
                      color: Colors.white.withOpacity(0.8),
                    ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: widget.onCancel,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'CANCEL',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 9,
                          letterSpacing: 2,
                          color: AetherColors.textSecondary,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

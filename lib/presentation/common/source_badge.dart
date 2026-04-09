import 'package:flutter/material.dart';
import '../../domain/entities/audio_source_type.dart';

class SourceBadge extends StatelessWidget {
  final AudioSourceType source;
  const SourceBadge({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color color;

    switch (source) {
      case AudioSourceType.local:
        iconData = Icons.phone_android_rounded;
        color = Colors.blueAccent.withOpacity(0.8);
        break;
      case AudioSourceType.youtube:
        iconData = Icons.play_circle_filled_rounded;
        color = Colors.redAccent.withOpacity(0.8);
        break;
      case AudioSourceType.spotify:
        iconData = Icons.circle_rounded;
        color = Colors.greenAccent.withOpacity(0.8);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(iconData, size: 10, color: color),
    );
  }
}

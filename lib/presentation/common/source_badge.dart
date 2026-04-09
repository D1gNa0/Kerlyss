import 'package:flutter/material.dart';
import '../state/audio_state.dart';

class SourceBadge extends StatelessWidget {
  final SourceType source;
  const SourceBadge({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color color;

    switch (source) {
      case SourceType.local:
        iconData = Icons.phone_android_rounded;
        color = Colors.blueAccent.withOpacity(0.8);
        break;
      case SourceType.youtube:
        iconData = Icons.play_circle_filled_rounded;
        color = Colors.redAccent.withOpacity(0.8);
        break;
      case SourceType.spotify:
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

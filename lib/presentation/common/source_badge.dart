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
        color = Colors.blueAccent.withValues(alpha: 0.8);
        break;
      case AudioSourceType.youtube:
        iconData = Icons.play_circle_filled_rounded;
        color = Colors.redAccent.withValues(alpha: 0.8);
        break;
      case AudioSourceType.spotify:
        iconData = Icons.circle_rounded;
        color = Colors.greenAccent.withValues(alpha: 0.8);
        break;
      case AudioSourceType.jamendo:
        iconData = Icons.library_music_rounded;
        color = Colors.orangeAccent.withValues(alpha: 0.8);
        break;
      case AudioSourceType.deezer:
        iconData = Icons.music_note_rounded;
        color = Colors.cyanAccent.withValues(alpha: 0.8);
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

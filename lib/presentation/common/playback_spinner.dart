import 'package:flutter/material.dart';

import '../theme/aether_colors.dart';

/// Small cyan spinner shown while a song is loading or re-buffering.
class PlaybackSpinner extends StatelessWidget {
  final double size;
  const PlaybackSpinner({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: size > 24 ? 3 : 2.2,
        valueColor: const AlwaysStoppedAnimation<Color>(AetherColors.accentCyan),
      ),
    );
  }
}

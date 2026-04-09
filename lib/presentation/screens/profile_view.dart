import 'package:flutter/material.dart';
import '../theme/aether_colors.dart';
import '../common/aether_glass.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AetherColors.deepMatteBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white10,
              child: Icon(Icons.person_outline_rounded, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              'AETHER GUEST',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 18,
                    letterSpacing: 4,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'PROXIMITY: ANONYMOUS',
              style: TextStyle(color: AetherColors.textSecondary, fontSize: 10, letterSpacing: 2),
            ),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: AetherGlass(
                borderRadius: 20,
                padding: const EdgeInsets.all(24),
                child: const Column(
                  children: [
                    Text(
                      'CLOUD SYNC NOT CONNECTED',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your library is currently stored locally on this device.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AetherColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

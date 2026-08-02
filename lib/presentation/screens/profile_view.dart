import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/aether_colors.dart';
import '../common/aether_glass.dart';
import '../state/auth_provider.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AetherColors.deepMatteBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'PROFILE',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 12,
                letterSpacing: 4,
              ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 46,
              backgroundColor: Colors.white10,
              child: Icon(Icons.person_outline_rounded, size: 46, color: Colors.white38),
            ),
            const SizedBox(height: 20),
            Text(
              'CLOUD SYNC & USER PROFILES',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 14,
                    letterSpacing: 3,
                  ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'COMING SOON',
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 36),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: AetherGlass(
                borderRadius: 20,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_sync_rounded, size: 36, color: Colors.white38),
                    const SizedBox(height: 14),
                    const Text(
                      'Local Storage Active',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Online user accounts and cloud library backup are currently under development. All your playlists, favorites, and downloaded tracks are safely stored locally on this device.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AetherColors.textSecondary, fontSize: 11, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    Opacity(
                      opacity: 0.5,
                      child: ElevatedButton(
                        onPressed: null, // Disabled / non-clickable
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: Colors.white10,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'FEATURE COMING SOON',
                          style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1),
                        ),
                      ),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/aether_colors.dart';
import '../common/aether_glass.dart';
import '../state/auth_provider.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

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
              authState.username,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 18,
                    letterSpacing: 4,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              authState.status == AuthStatus.authenticated ? 'PROXIMITY: ENCRYPTED SECURE' : 'PROXIMITY: ANONYMOUS',
              style: const TextStyle(color: AetherColors.textSecondary, fontSize: 10, letterSpacing: 2),
            ),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: AetherGlass(
                borderRadius: 20,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      authState.status == AuthStatus.authenticated ? 'CLOUD SYNC ACTIVE' : 'CLOUD SYNC NOT CONNECTED',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      authState.status == AuthStatus.authenticated 
                          ? 'Your library is securely mirrored to the Aether Network.'
                          : 'Your library is currently stored locally on this device.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AetherColors.textSecondary, fontSize: 11),
                    ),
                    const SizedBox(height: 24),
                    authState.status == AuthStatus.authenticated
                        ? ElevatedButton(
                            onPressed: () => ref.read(authProvider.notifier).logout(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white12,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('DISCONNECT', style: TextStyle(color: Colors.white)),
                          )
                        : ElevatedButton(
                            onPressed: () => ref.read(authProvider.notifier).login(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('CONNECT TO AETHER', style: TextStyle(color: Colors.white)),
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

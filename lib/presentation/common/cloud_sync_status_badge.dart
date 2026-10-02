import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/toast_service.dart';
import '../state/cloud_sync_provider.dart';
import '../theme/aether_colors.dart';

class CloudSyncStatusBadge extends ConsumerWidget {
  const CloudSyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(cloudSyncProvider);

    if (!syncState.isConnected) {
      return const SizedBox.shrink();
    }

    if (syncState.isSyncing) {
      return _buildPill(
        context: context,
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        borderColor: Colors.white.withValues(alpha: 0.15),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
            SizedBox(width: 6),
            Text(
              'Syncing...',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    }

    if (syncState.errorMessage != null) {
      return _buildPill(
        context: context,
        backgroundColor: AetherColors.error.withValues(alpha: 0.15),
        borderColor: AetherColors.error.withValues(alpha: 0.4),
        onTap: () => _showErrorDialog(context, ref, syncState.errorMessage!),
        tooltip: 'Sync error — Tap for details',
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 14,
              color: AetherColors.error,
            ),
            SizedBox(width: 5),
            Text(
              'Sync error',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AetherColors.error,
              ),
            ),
          ],
        ),
      );
    }

    if (syncState.hasPendingChanges) {
      final count = syncState.pendingCount;
      return _buildPill(
        context: context,
        backgroundColor: AetherColors.warning.withValues(alpha: 0.12),
        borderColor: AetherColors.warning.withValues(alpha: 0.3),
        onTap: () async {
          ToastService.show(context, 'Syncing pending changes with Google Drive...');
          final ok = await ref.read(cloudSyncProvider.notifier).syncNow();
          if (context.mounted) {
            ToastService.show(context, ok ? 'Cloud sync complete!' : 'Sync failed');
          }
        },
        tooltip: '$count pending changes — Tap to sync now',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_upload_rounded,
              size: 14,
              color: AetherColors.warning,
            ),
            const SizedBox(width: 5),
            Text(
              '$count pending',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AetherColors.warning,
              ),
            ),
          ],
        ),
      );
    }

    // Connected & Synced
    return _buildPill(
      context: context,
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      borderColor: Colors.white.withValues(alpha: 0.08),
      onTap: () async {
        ToastService.show(context, 'Syncing library with Google Drive...');
        final ok = await ref.read(cloudSyncProvider.notifier).syncNow();
        if (context.mounted) {
          ToastService.show(context, ok ? 'Cloud sync complete!' : 'Sync failed');
        }
      },
      tooltip: 'Google Drive Synced • Tap to refresh',
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_done_rounded,
            size: 14,
            color: Colors.white60,
          ),
          SizedBox(width: 5),
          Text(
            'Synced',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required BuildContext context,
    required Color backgroundColor,
    required Color borderColor,
    required Widget child,
    VoidCallback? onTap,
    String? tooltip,
  }) {
    Widget pill = Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Center(child: child),
    );

    if (onTap != null) {
      pill = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: pill,
      );
    }

    if (tooltip != null) {
      pill = Tooltip(
        message: tooltip,
        child: pill,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: pill,
    );
  }

  void _showErrorDialog(BuildContext context, WidgetRef ref, String errorMessage) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AetherColors.ultraDarkGray,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: AetherColors.error, size: 20),
            SizedBox(width: 8),
            Text(
              'CLOUD SYNC ERROR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              errorMessage,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            Text(
              'Make sure Google Drive API is enabled in your Google Cloud project and your device is online.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11, height: 1.3),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('DISMISS', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              ToastService.show(context, 'Retrying cloud sync...');
              final ok = await ref.read(cloudSyncProvider.notifier).syncNow();
              if (context.mounted) {
                ToastService.show(context, ok ? 'Cloud sync complete!' : 'Sync failed again');
              }
            },
            child: const Text('RETRY', style: TextStyle(color: AetherColors.accentCyan)),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/update_provider.dart';
import '../theme/aether_colors.dart';

/// Floating update status (like VS Code's "Restart to update" / Epic's updater):
/// download progress -> "Restart to update" (Windows) / "Install" (Android).
/// Must be a direct child of a [Stack] because it returns a [Positioned].
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateProvider);
    if (!state.showsBanner) return const SizedBox.shrink();

    final controller = ref.read(updateProvider.notifier);
    final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    final top = MediaQuery.of(context).padding.top + (isDesktop ? 48 : 8);
    final version = state.info?.version ?? '';

    Widget leading;
    Widget body;
    Widget? action;

    switch (state.phase) {
      case UpdatePhase.downloading:
        final pct = (state.progress * 100).clamp(0, 100).toInt();
        final mb = state.totalBytes > 0
            ? ' · ${(state.receivedBytes / 1048576).toStringAsFixed(1)} / ${(state.totalBytes / 1048576).toStringAsFixed(1)} MB'
            : '';
        leading = const Icon(Icons.system_update_alt_rounded, color: AetherColors.accentCyan, size: 20);
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Downloading update $version', style: _title),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: state.progress > 0 ? state.progress : null,
              minHeight: 3,
              color: AetherColors.accentCyan,
              backgroundColor: Colors.white12,
            ),
            const SizedBox(height: 4),
            Text('$pct%$mb', style: _sub),
          ],
        );
        action = IconButton(
          tooltip: 'Cancel',
          visualDensity: VisualDensity.compact,
          onPressed: controller.cancel,
          icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
        );
      case UpdatePhase.verifying:
      case UpdatePhase.preparing:
        leading = const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: AetherColors.accentCyan),
        );
        body = Text(
          state.phase == UpdatePhase.verifying ? 'Verifying update…' : 'Preparing update…',
          style: _title,
        );
      case UpdatePhase.readyToInstall:
        final isWindows = Platform.isWindows;
        leading = const Icon(Icons.check_circle_rounded, color: AetherColors.success, size: 20);
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Update $version is ready', style: _title),
            if (state.message != null) ...[
              const SizedBox(height: 4),
              Text(state.message!, style: _sub),
            ],
          ],
        );
        action = FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AetherColors.accentCyan,
            foregroundColor: Colors.black,
            visualDensity: VisualDensity.compact,
          ),
          onPressed: controller.installNow,
          child: Text(isWindows ? 'Restart to update' : 'Install', style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      case UpdatePhase.error:
        leading = const Icon(Icons.error_outline_rounded, color: AetherColors.error, size: 20);
        body = Text(state.message ?? 'Update failed', style: _title);
        action = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.info != null)
              TextButton(
                onPressed: controller.startUpdate,
                child: const Text('Retry', style: TextStyle(color: AetherColors.accentCyan)),
              ),
            IconButton(
              tooltip: 'Dismiss',
              visualDensity: VisualDensity.compact,
              onPressed: controller.dismissError,
              icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }

    return Positioned(
      top: top,
      right: 12,
      left: isDesktop ? null : 12,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Material(
          color: AetherColors.ultraDarkGray.withValues(alpha: 0.96),
          elevation: 8,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AetherColors.accentCyan.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 12),
                Expanded(child: body),
                if (action != null) ...[const SizedBox(width: 8), action],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const TextStyle _title = TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600);
  static const TextStyle _sub = TextStyle(color: Colors.white54, fontSize: 11);
}

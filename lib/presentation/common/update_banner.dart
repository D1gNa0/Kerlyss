import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/update_provider.dart';
import '../theme/aether_colors.dart';

/// Wraps the whole app (used in `MaterialApp.builder`, so it sits ABOVE the Navigator).
///
/// While an update is downloading / ready / failed, a slim bar is added at the very
/// bottom of the window. Because it is above the Navigator it shows on EVERY screen
/// (Settings, Profile, full player, ...) and not only on the home screen.
/// The bar takes its own space (it does not float), so it never covers any button.
class UpdateDock extends ConsumerWidget {
  const UpdateDock({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final show = ref.watch(updateProvider.select((s) => s.showsBanner));
    final media = MediaQuery.of(context);

    // The bar already keeps clear of the system navigation bar, so the app above it
    // must not add that space a second time.
    // Keep the tree the same shape for both cases (always a MediaQuery) so the
    // Navigator and every screen keep their state when the bar appears/disappears.
    final appMedia = show
        ? media.copyWith(
            padding: media.padding.copyWith(bottom: 0),
            viewPadding: media.viewPadding.copyWith(bottom: 0),
          )
        : media;

    return Column(
      children: [
        Expanded(child: MediaQuery(data: appMedia, child: child)),
        if (show) const UpdateBanner(),
      ],
    );
  }
}

/// The update status bar: download progress -> "Restart to update" (Windows) / "Install" (Android).
/// Shown by [UpdateDock]. It lives above the Navigator, so there is no Overlay here:
/// do not use `tooltip:` on buttons inside it.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateProvider);
    if (!state.showsBanner) return const SizedBox.shrink();

    final controller = ref.read(updateProvider.notifier);
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
            Text('Downloading update $version', style: _title, maxLines: 1, overflow: TextOverflow.ellipsis),
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
        // Windows installs a ready update by itself when the app is closed.
        final hint = state.message ?? (isWindows ? 'It installs automatically when you close Kerlyss.' : null);
        leading = const Icon(Icons.check_circle_rounded, color: AetherColors.success, size: 20);
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Update $version is ready', style: _title, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (hint != null) ...[
              const SizedBox(height: 4),
              Text(hint, style: _sub),
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
              visualDensity: VisualDensity.compact,
              onPressed: controller.dismissError,
              icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }

    return Material(
      color: AetherColors.ultraDarkGray,
      child: Container(
        width: double.infinity,
        // The bar sits at the bottom edge: keep it above the system navigation bar.
        padding: EdgeInsets.fromLTRB(16, 10, 12, 10 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AetherColors.accentCyan.withValues(alpha: 0.25))),
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
    );
  }

  static const TextStyle _title = TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600);
  static const TextStyle _sub = TextStyle(color: Colors.white54, fontSize: 11);
}

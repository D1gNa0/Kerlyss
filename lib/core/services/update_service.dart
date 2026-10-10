import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../presentation/state/update_provider.dart';
import 'app_updater.dart';
import 'toast_service.dart';

/// Thin UI entry point (kept so existing call sites keep working).
/// The real work lives in [UpdateController] (state) and [AppUpdater] (logic).
class UpdateService {
  static const String _releasePageUrl = 'https://d1gna0.github.io/Kerlyss/';

  /// [manual] = the user pressed "Check for updates" (so we also tell them when
  /// there is nothing new or the check failed). At startup it stays silent.
  Future<void> checkForUpdates(
    BuildContext context, {
    bool manual = false,
    UpdateChannel channel = UpdateChannel.stable,
  }) async {
    final container = ProviderScope.containerOf(context);
    final controller = container.read(updateProvider.notifier);
    final current = container.read(updateProvider);

    if (current.isBusy) {
      if (manual) ToastService.show(context, 'An update is already in progress');
      return;
    }

    if (current.phase == UpdatePhase.readyToInstall) {
      if (manual && context.mounted) _showDialog(context, controller, current);
      return;
    }

    final result = await controller.check(channel: channel);
    if (!context.mounted) return;

    switch (result) {
      case UpdateCheckResult.available:
        _showDialog(context, controller, container.read(updateProvider));
      case UpdateCheckResult.upToDate:
        if (manual) {
          ToastService.show(
            context,
            channel == UpdateChannel.beta ? 'No newer beta is available right now' : "You're on the latest version",
          );
        }
      case UpdateCheckResult.failed:
        if (manual) {
          ToastService.show(
            context,
            channel == UpdateChannel.beta ? "Couldn't check for beta updates" : "Couldn't check for updates",
            backgroundColor: Colors.redAccent,
          );
        }
    }
  }

  /// "Check for Beta Updates" button. Beta is opt-in: the startup check never looks for betas.
  Future<void> checkForBetaUpdates(BuildContext context) =>
      checkForUpdates(context, manual: true, channel: UpdateChannel.beta);

  void _showDialog(BuildContext context, UpdateController controller, UpdateState state) {
    final info = state.info;
    if (info == null) return;
    final ready = state.phase == UpdatePhase.readyToInstall;
    final isBeta = info.isBeta;
    final inApp = AppUpdater.supportsInAppUpdate;
    final isWindows = Theme.of(context).platform == TargetPlatform.windows;

    final primaryLabel = !inApp
        ? 'Download'
        : ready
            ? (isWindows ? 'Restart to update' : 'Install')
            : 'Update';

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          ready
              ? '${isBeta ? 'Beta' : 'Update'} ready: ${info.version}'
              : '${isBeta ? 'Beta Available' : 'Update Available'}: ${info.version}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 260),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBeta ? 'A beta version of Kerlyss is ready to try!' : 'A new version of Kerlyss is ready!',
                  style: const TextStyle(color: Colors.white70),
                ),
                if (isBeta) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Beta builds can be unstable. On Android, going back to the stable version may require '
                    'uninstalling the app first (your cloud-synced data stays safe).',
                    style: TextStyle(color: Colors.amberAccent, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 12),
                Text(info.notes, style: const TextStyle(color: Colors.white60, fontSize: 14)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Later', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA855F7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (!inApp) {
                // iOS / macOS / Linux: no in-app installer, open the download page.
                await launchUrl(Uri.parse(_releasePageUrl), mode: LaunchMode.externalApplication);
              } else if (ready) {
                await controller.installNow();
              } else {
                await controller.startUpdate();
              }
            },
            child: Text(primaryLabel),
          ),
        ],
      ),
    );
  }
}

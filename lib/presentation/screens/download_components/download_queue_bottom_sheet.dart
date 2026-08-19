import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/aether_glass.dart';
import '../../common/aether_network_image.dart';
import '../../common/vercel_hover_button.dart';
import '../../theme/aether_colors.dart';
import '../../state/download_state_provider.dart';
import '../../state/track_download_provider.dart';

class DownloadQueueBottomSheet extends ConsumerWidget {
  const DownloadQueueBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const DownloadQueueBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(downloadStateProvider);
    final queueIds = state.downloadQueueOrder;
    final totalCount = state.isBulkActive ? state.bulkTotal : queueIds.length;
    final completedCount = state.bulkCompleted;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      margin: const EdgeInsets.all(16),
      child: AetherGlass(
        borderRadius: 24,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.downloading_rounded, color: AetherColors.primaryAccent, size: 22),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ACTIVE DOWNLOAD QUEUE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        if (state.isBulkActive)
                          Text(
                            'Batch Progress: $completedCount of $totalCount Completed',
                            style: const TextStyle(
                              color: AetherColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (queueIds.isNotEmpty || state.isBulkActive)
                  TextButton(
                    onPressed: () {
                      ref.read(trackDownloadServiceProvider).cancelBulkDownload();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'CANCEL ALL',
                      style: TextStyle(
                        color: AetherColors.error,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Queue List
            if (queueIds.isEmpty && !state.isBulkActive)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'No active downloads in queue',
                    style: TextStyle(color: AetherColors.textSecondary, fontSize: 13),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: queueIds.length,
                  itemBuilder: (context, index) {
                    final songId = queueIds[index];
                    final song = state.activeDownloadSongs[songId];
                    final isDownloading = state.downloadingTrackIds.contains(songId);
                    final progress = state.downloadProgress[songId] ?? 0.0;
                    final progressPct = (progress * 100).toInt();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDownloading
                                ? AetherColors.primaryAccent.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: AetherNetworkImage(
                                    url: song?.albumArtUrl ?? 'https://picsum.photos/seed/placeholder/200/200',
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        song?.title ?? songId,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isDownloading
                                            ? (progress > 0 ? 'Downloading... $progressPct%' : 'Starting download...')
                                            : 'Queued position #${index + 1}',
                                        style: TextStyle(
                                          color: isDownloading ? AetherColors.primaryAccent : AetherColors.textSecondary,
                                          fontSize: 11,
                                          fontWeight: isDownloading ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  isDownloading ? '$progressPct%' : 'QUEUED',
                                  style: TextStyle(
                                    color: isDownloading ? AetherColors.primaryAccent : Colors.white38,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (isDownloading) ...[
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress > 0 ? progress : null,
                                  minHeight: 4,
                                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                                  valueColor: const AlwaysStoppedAnimation<Color>(AetherColors.primaryAccent),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

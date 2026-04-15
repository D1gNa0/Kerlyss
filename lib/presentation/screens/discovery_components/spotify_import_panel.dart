import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/import_state_provider.dart';
import '../../state/discovery_search_provider.dart';

class SpotifyImportPanel extends ConsumerWidget {
  const SpotifyImportPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final importState = ref.watch(importStateProvider);
    final searchState = ref.watch(discoverySearchProvider);
    final isImporting = importState.status == ImportStatus.analyzing || importState.status == ImportStatus.resolving;

    // Auto-reset search mode when import succeeds
    ref.listen<ImportState>(importStateProvider, (previous, next) {
      if (next.status == ImportStatus.complete && previous?.status != ImportStatus.complete) {
        ref.read(discoverySearchProvider.notifier).toggleSearchMode();

        // Show success notification and any failures
        final failCount = next.failedTracks.length;
        final successMsg = failCount > 0
            ? 'Imported playlist "${next.playlistName}". $failCount tracks could not be resolved.'
            : 'Successfully imported "${next.playlistName}"!';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMsg),
            backgroundColor: Colors.green.shade800,
            duration: const Duration(seconds: 5),
          ),
        );
        ref.read(importStateProvider.notifier).reset();
      } else if (next.status == ImportStatus.error && previous?.status != ImportStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? 'Import failed'),
            backgroundColor: Colors.redAccent,
          ),
        );
        ref.read(importStateProvider.notifier).reset();
      }
    });

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.queue_music_rounded, size: 64, color: Colors.lightGreenAccent),
            const SizedBox(height: 16),
            const Text(
              'Spotify Playlist Importer',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Paste a public Spotify playlist link into the search bar above to import its tracks into Kerlyss.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 24),
            if (isImporting) ...[
              CircularProgressIndicator(
                value: importState.status == ImportStatus.resolving
                    ? (importState.processedTracks / (importState.totalTracks > 0 ? importState.totalTracks : 1))
                    : null,
                color: Colors.lightGreenAccent,
              ),
              const SizedBox(height: 16),
              Text(
                importState.status == ImportStatus.analyzing
                    ? 'Analyzing Spotify Playlist...'
                    : 'Resolving ${importState.processedTracks} of ${importState.totalTracks} tracks...',
                style: const TextStyle(color: Colors.white),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: searchState.query.isNotEmpty && searchState.query.contains('spotify.com')
                    ? () {
                        // Dismiss keyboard
                        FocusScope.of(context).unfocus();
                        ref.read(importStateProvider.notifier).importSpotifyPlaylist(
                              searchState.query,
                              searchState.downloadOnImport,
                            );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreenAccent.withOpacity(0.2),
                  foregroundColor: Colors.lightGreenAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Start Import', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

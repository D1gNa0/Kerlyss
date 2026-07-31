import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/aether_glass.dart';
import '../../theme/aether_colors.dart';
import '../../state/import_state_provider.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../data/models/spotify_metadata_model.dart';
import '../../../data/models/spotify_playlist_model.dart';

class SpotifyPreImportModal extends ConsumerStatefulWidget {
  final String spotifyUrl;

  const SpotifyPreImportModal({
    super.key,
    required this.spotifyUrl,
  });

  @override
  ConsumerState<SpotifyPreImportModal> createState() => _SpotifyPreImportModalState();
}

class _SpotifyPreImportModalState extends ConsumerState<SpotifyPreImportModal> {
  bool _isRealtimeSynced = true;
  bool _autoDownloadNewTracks = false;
  bool _isLoading = true;
  String? _error;

  SpotifyMetadataModel? _metadata;
  SpotifyPlaylistModel? _playlistData;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    try {
      final spotifyService = ref.read(spotifyPublicServiceProvider);
      final metaFuture = spotifyService.fetchMetadata(widget.spotifyUrl);
      final dataFuture = spotifyService.extractPlaylistData(widget.spotifyUrl);

      final results = await Future.wait([metaFuture, dataFuture]);
      if (mounted) {
        setState(() {
          _metadata = results[0] as SpotifyMetadataModel;
          _playlistData = results[1] as SpotifyPlaylistModel;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load Spotify preview. Verify link and network.';
          _isLoading = false;
        });
      }
    }
  }

  void _onImportPressed() {
    Navigator.of(context).pop();
    ref.read(importStateProvider.notifier).importSpotifyPlaylist(
          widget.spotifyUrl,
          _autoDownloadNewTracks,
          isRealtimeSynced: _isRealtimeSynced,
          autoDownloadNewTracks: _autoDownloadNewTracks,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: AetherColors.ultraDarkGray,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 250,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.lightGreenAccent),
                    SizedBox(height: 16),
                    Text(
                      'PREVIEWING SPOTIFY LINK...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _error != null
              ? SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Header Card
                      AetherGlass(
                        borderRadius: 16,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _metadata?.thumbnailUrl ?? '',
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 72,
                                  height: 72,
                                  color: Colors.white10,
                                  child: const Icon(Icons.music_note, color: Colors.white54),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _metadata?.title ?? _playlistData?.name ?? 'Spotify Playlist',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Spotify Playlist',
                                    style: TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.lightGreenAccent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${_playlistData?.trackQueries.length ?? 0} Tracks',
                                      style: const TextStyle(
                                        color: Colors.lightGreenAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      const Text(
                        'TRACK PREVIEW',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // First 3-4 track previews
                      ...(_playlistData?.trackQueries.take(4) ?? []).map(
                        (track) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.music_note_rounded, color: Colors.white24, size: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  track,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 12),

                      // Sync Toggles
                      SwitchListTile(
                        value: _isRealtimeSynced,
                        activeColor: Colors.lightGreenAccent,
                        contentPadding: EdgeInsets.zero,
                        title: const Row(
                          children: [
                            Icon(Icons.bolt_rounded, color: Colors.amberAccent, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Real-Time Sync',
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        subtitle: const Text(
                          'Automatically fetch new songs when opening this playlist',
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                        onChanged: (val) => setState(() => _isRealtimeSynced = val),
                      ),

                      SwitchListTile(
                        value: _autoDownloadNewTracks,
                        activeColor: Colors.lightGreenAccent,
                        contentPadding: EdgeInsets.zero,
                        title: const Row(
                          children: [
                            Icon(Icons.download_for_offline_rounded, color: Colors.cyanAccent, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Auto-Download New Tracks',
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        subtitle: const Text(
                          'Download audio files for offline playback automatically',
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                        onChanged: (val) => setState(() => _autoDownloadNewTracks = val),
                      ),

                      const SizedBox(height: 24),

                      // Primary Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _onImportPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightGreenAccent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Text(
                            'IMPORT PLAYLIST',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

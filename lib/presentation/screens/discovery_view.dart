import '../state/download_state_provider.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../common/aether_glass.dart';
import '../common/aether_source_bottom_sheet.dart';
import '../common/source_badge.dart';
import '../state/discovery_search_provider.dart';
import '../state/audio_provider.dart';
import '../state/audio_state.dart';
import '../state/library_provider.dart';
import '../state/downloaded_songs_provider.dart';
import '../state/keyboard_shortcuts_provider.dart';
import '../../core/services/logger_service.dart';
import '../../core/services/app_storage_paths.dart';
import '../../data/datasources/remote/youtube_service.dart';

import '../../data/repositories/repository_providers.dart';
import '../../domain/entities/audio_source_type.dart';
import '../../data/models/song_model.dart';
import '../../domain/entities/song_entity.dart';
import '../../data/datasources/remote/jamendo_service.dart';

import '../state/playlist_provider.dart';
import 'playlists_view.dart';
import '../theme/aether_colors.dart';



class DiscoveryView extends ConsumerStatefulWidget {
  const DiscoveryView({super.key});

  @override
  ConsumerState<DiscoveryView> createState() => _DiscoveryViewState();
}

class _DiscoveryViewState extends ConsumerState<DiscoveryView> {
  bool _hasShownMissingKeyWarning = false;
  final FocusNode _searchFocusNode = FocusNode();


  void _showEnvSetupInstructions() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF171717),
          title: const Text(
            'Jamendo Setup',
            style: TextStyle(color: Colors.white),
          ),
          content: const SingleChildScrollView(
            child: Text(
              '1. Open the project root file named .env\n'
              '2. Set JAMENDO_CLIENT_ID=your_key\n'
              '3. Save the file\n'
              '4. Fully restart the app (not just hot reload)\n\n'
              'Example:\n'
              'JAMENDO_CLIENT_ID=abc123yourkey',
              style: TextStyle(color: Colors.white70, height: 1.35),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_syncShortcutSuppression);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showMissingKeyWarningIfNeeded();
    });
  }

  void _syncShortcutSuppression() {
    if (!mounted) {
      return;
    }

    ref.read(keyboardShortcutsSuppressedProvider.notifier).state = _searchFocusNode.hasFocus;
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_syncShortcutSuppression);
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _showMissingKeyWarningIfNeeded() {
    if (_hasShownMissingKeyWarning || !mounted) {
      return;
    }

    final jamendoService = ref.read(jamendoServiceProvider);
    final hasDotenvKey = dotenv.env.containsKey('JAMENDO_CLIENT_ID');
    final dotenvKey = (dotenv.env['JAMENDO_CLIENT_ID'] ?? '').trim();

    if (jamendoService.isConfigured || !hasDotenvKey || dotenvKey.isNotEmpty) {
      return;
    }

    _hasShownMissingKeyWarning = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('JAMENDO_CLIENT_ID is empty in .env. Add your key to enable INSTALL.'),
        backgroundColor: Colors.amber,
      ),
    );
  }

  Future<void> _updateExistingDownloads() async {
    final searchState = ref.read(discoverySearchProvider);
    if (searchState.results.isEmpty) return;

    final isarService = ref.read(isarDatabaseServiceProvider);
    final newAlreadyDownloaded = <String>{};

    for (final song in searchState.results) {
      final existing = await isarService.getSongById(song.id);
      if (existing != null && existing.localPath != null) {
        // Verify file still exists on disk
        if (await File(existing.localPath!).exists()) {
          newAlreadyDownloaded.add(song.id);
        }
      }
    }

    if (mounted) {
      setState(() {

        ref.read(downloadStateProvider.notifier).setAlreadyDownloaded(newAlreadyDownloaded);
      });
    }
  }

  bool _isDownloading(String songId) => ref.read(downloadStateProvider).downloadingTrackIds.contains(songId);
  bool _isAlreadyDownloaded(String songId) => ref.read(downloadStateProvider).alreadyDownloadedIds.contains(songId);
  double _getProgress(String songId) => ref.read(downloadStateProvider).downloadProgress[songId] ?? 0.0;


  Future<void> _downloadJamendoTrack(SongEntity song) async {
    if (song.sourceType != AudioSourceType.jamendo) {
      return;
    }

    ref.read(downloadStateProvider.notifier).setDownloading(song.id);

    try {
      final jamendoService = ref.read(jamendoServiceProvider);
      final downloadedSong = await jamendoService.downloadTrack(song);

      if (!mounted) {
        return;
      }

      // Persist in Isar
      final isarService = ref.read(isarDatabaseServiceProvider);
      await isarService.updateLocalPath(
        SongModel.fromEntity(song), 
        downloadedSong.path,
      );


      ref.invalidate(downloadedSongsProvider);
      await _updateExistingDownloads();
      
      Log.i('Jamendo download completed for ${song.id}: Saved to ${downloadedSong.path}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded ${downloadedSong.title} to Downloads.')),
      );
    } catch (e) {

      Log.e('Jamendo download failed for ${song.id}: $e');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download ${song.title}.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        ref.read(downloadStateProvider.notifier).completeDownload(song.id);
      }
    }
  }

  Future<void> _downloadYoutubeTrack(SongEntity song) async {
    if (song.sourceType != AudioSourceType.youtube) {
      return;
    }

    ref.read(downloadStateProvider.notifier).setDownloading(song.id);

    try {
      final youtubeService = ref.read(youtubeServiceProvider);
      final downloadsDirectory = await AppStoragePaths.downloadsDirectory();

      // Building a meaningful filename for the download
      final destinationPath = YoutubeService.buildDestinationPath(
        downloadsDirectory.path,
        song.id,
        song.title,
      );


      await youtubeService.downloadTrack(
        song.id,
        destinationPath,
        onProgress: (progress) {
          if (mounted) {
            ref.read(downloadStateProvider.notifier).updateProgress(song.id, progress);
          }
        },
      );


      if (!mounted) {
        return;
      }

      // Persist in Isar
      final isarService = ref.read(isarDatabaseServiceProvider);
      await isarService.updateLocalPath(
        SongModel.fromEntity(song), 
        destinationPath,
      );


      ref.invalidate(downloadedSongsProvider);
      await _updateExistingDownloads();

      Log.i('YouTube download completed for ${song.id}: Saved to $destinationPath');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded ${song.title} to local storage.')),
      );
    } catch (e) {

      Log.e('YouTube download failed for ${song.id}: $e');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download ${song.title} from YouTube.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        ref.read(downloadStateProvider.notifier).completeDownload(song.id);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final searchState = ref.watch(discoverySearchProvider);
    
    // Auto-check for existing downloads whenever results change
    ref.listen(discoverySearchProvider, (previous, next) {
      if (previous?.results.length != next.results.length || next.results.isNotEmpty) {
        _updateExistingDownloads();
      }
    });

    final jamendoConfigured = ref.watch(jamendoServiceProvider).isConfigured;

    final jamendoResultsCount = searchState.results
        .where((song) => song.sourceType == AudioSourceType.jamendo)
        .length;
    ref.watch(libraryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // Header — no actions, clean
          SliverAppBar(
            expandedHeight: 100,
            backgroundColor: Colors.transparent,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'DISCOVER',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontSize: 14,
                      letterSpacing: 8,
                      color: Colors.white38,
                    ),
              ),
            ),
          ),
          
          // Search Input + Import Button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: AetherGlass(
                        borderRadius: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        child: TextField(
                          focusNode: _searchFocusNode,
                          onChanged: (value) {
                            ref.read(discoverySearchProvider.notifier).onSearchQueryChanged(value);
                            // Trigger duplicate check after search results update (small delay for notifier)
                            Future.delayed(const Duration(milliseconds: 600), _updateExistingDownloads);
                          },
                          style: const TextStyle(color: Colors.white, fontSize: 14),

                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'SEARCH SONGS, ARTISTS...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.2),
                              fontSize: 12,
                              letterSpacing: 2,
                            ),
                            icon: const Icon(Icons.search_rounded, color: Colors.white24, size: 20),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Import Source button — paste a YouTube/Spotify link
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: AetherGlass(
                      borderRadius: 16,
                      padding: EdgeInsets.zero,
                      child: IconButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (context) => const AetherSourceBottomSheet(),
                          );
                        },
                        icon: const Icon(Icons.add_link_rounded, color: Colors.white70, size: 22),
                        tooltip: 'Import from YouTube / Spotify link',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: SizedBox(
                height: 78,
                child: AetherGlass(
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        jamendoConfigured ? Icons.download_done_rounded : Icons.key_off_rounded,
                        color: jamendoConfigured ? Colors.lightGreenAccent : Colors.amberAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          jamendoConfigured
                              ? 'Jamendo downloads enabled. Search songs and tap INSTALL to save MP3 files into Downloads.'
                              : 'Jamendo key missing. Set JAMENDO_CLIENT_ID to enable INSTALL for Jamendo tracks.',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ),
                      if (!jamendoConfigured)
                        TextButton(
                          onPressed: _showEnvSetupInstructions,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white.withOpacity(0.06),
                            minimumSize: const Size(64, 28),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text(
                            '.env',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      if (!jamendoConfigured)
                        const SizedBox(width: 8),
                      if (searchState.query.isNotEmpty)
                        Text(
                          '$jamendoResultsCount',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Result Body
          if (searchState.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Colors.white24)),
            )
          else if (searchState.results.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = searchState.results[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        tileColor: Colors.white.withOpacity(0.02),
                        leading: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                song.albumArtUrl ?? 'https://picsum.photos/seed/placeholder/200/200',
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 44,
                                  height: 44,
                                  color: Colors.white10,
                                  child: const Icon(Icons.music_note_rounded, color: Colors.white38, size: 20),
                                ),
                              ),
                            ),
                            SourceBadge(source: song.sourceType),
                          ],
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_isDownloading(song.id))
                              Padding(
                                padding: const EdgeInsets.only(top: 6.0, right: 20),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: _getProgress(song.id),
                                    backgroundColor: Colors.white.withOpacity(0.05),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white30),
                                    minHeight: 2,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        subtitle: Text(
                          song.sourceType == AudioSourceType.jamendo
                              ? '${song.artist}  •  Tap INSTALL to save'
                              : song.artist,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (song.sourceType == AudioSourceType.jamendo ||
                                song.sourceType == AudioSourceType.youtube)
                              Padding(
                                padding: const EdgeInsets.only(right: 4.0),
                                child: _isAlreadyDownloaded(song.id)
                                    ? const SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: Center(
                                          child: Icon(Icons.check_circle_rounded,
                                              color: Colors.lightGreenAccent, size: 20),
                                        ),
                                      )
                                    : IconButton(
                                        onPressed: _isDownloading(song.id)
                                            ? null
                                            : () {
                                                if (song.sourceType == AudioSourceType.jamendo) {
                                                  _downloadJamendoTrack(song);
                                                } else if (song.sourceType == AudioSourceType.youtube) {
                                                  _downloadYoutubeTrack(song);
                                                }
                                              },
                                        icon: _isDownloading(song.id)
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38),
                                              )
                                            : const Icon(Icons.download_rounded, color: Colors.white30, size: 20),
                                        tooltip: 'Install to local library',
                                      ),
                              ),
                            IconButton(
                              icon: Icon(
                                ref.read(libraryProvider.notifier).isSongFavorite(song.id)
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: ref.read(libraryProvider.notifier).isSongFavorite(song.id)
                                    ? Colors.redAccent
                                    : Colors.white24,
                                size: 18,
                              ),
                              onPressed: () {
                                ref.read(libraryProvider.notifier).toggleFavorite(song);
                              },
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded, color: Colors.white24, size: 20),
                              padding: EdgeInsets.zero,
                              color: AetherColors.ultraDarkGray,
                              offset: const Offset(0, 40),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onSelected: (value) {
                                if (value == 'add_to_playlist') {
                                  _showAddToPlaylistDialog(context, ref, song);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'add_to_playlist',
                                  child: Row(
                                    children: [
                                      Icon(Icons.playlist_add_rounded, color: Colors.white70, size: 18),
                                      SizedBox(width: 8),
                                      Text('Add to Playlist', style: TextStyle(color: Colors.white, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        onTap: () {
                          // Convert search results to a playlist
                          final playlist = searchState.results.map((s) => SongMetadata(
                            id: s.id,
                            title: s.title,
                            artist: s.artist,
                            album: s.album,
                            artworkUrl: s.albumArtUrl,
                            duration: s.duration,
                            source: s.sourceType,
                          )).toList();
                          
                          ref.read(audioProvider.notifier).playPlaylist(playlist, index);
                        },

                      ),
                    );
                  },
                  childCount: searchState.results.length,
                ),
              ),
            )
          else if (searchState.error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'SEARCH FAILED',
                        style: const TextStyle(color: Colors.redAccent, letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        searchState.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.explore_outlined, color: Colors.white10, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      searchState.query.isEmpty ? 'START YOUR SEARCH' : 'NO RESULTS FOUND',
                      style: const TextStyle(color: Colors.white12, letterSpacing: 2, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, WidgetRef ref, SongEntity song) {
    final playlistState = ref.read(playlistProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AetherColors.ultraDarkGray,
        title: const Text('ADD TO PLAYLIST', style: TextStyle(color: Colors.white, fontSize: 13, letterSpacing: 2)),
        content: playlistState.playlists.isEmpty
            ? const Text('No playlists found. Create one first!', style: TextStyle(color: Colors.white38, fontSize: 12))
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlistState.playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlistState.playlists[index];
                    return ListTile(
                      title: Text(playlist.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      onTap: () {
                        ref.read(playlistProvider.notifier).addSongToPlaylist(playlist.id, song);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added to ${playlist.name}'), backgroundColor: Colors.white10),
                        );
                      },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: Color(0x57FFFFFF))),

          ),
        ],
      ),
    );
  }
}


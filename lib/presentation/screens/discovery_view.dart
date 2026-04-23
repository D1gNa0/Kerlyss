import 'discovery_components/discovery_results_list.dart';
import 'discovery_components/spotify_import_panel.dart';
import 'discovery_components/discovery_search_bar.dart';
import 'discovery_components/discovery_recommendations.dart';
import 'discovery_components/discovery_error_state.dart';


import '../state/download_state_provider.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../common/aether_glass.dart';
import '../common/aether_source_bottom_sheet.dart';

import '../state/discovery_search_provider.dart';


import '../state/library_provider.dart';
import '../state/downloaded_songs_provider.dart';
import '../state/keyboard_shortcuts_provider.dart';
import '../../core/services/logger_service.dart';
import '../../core/services/app_storage_paths.dart';
import '../../core/services/toast_service.dart';
import '../../data/datasources/remote/youtube_service.dart';

import '../../data/repositories/repository_providers.dart';
import '../../domain/entities/audio_source_type.dart';
import '../../data/models/song_model.dart';
import '../../domain/entities/song_entity.dart';


import '../state/playlist_provider.dart';
import '../state/track_download_provider.dart';

import '../theme/aether_colors.dart';

class DiscoveryView extends ConsumerStatefulWidget {
  const DiscoveryView({super.key});

  @override
  ConsumerState<DiscoveryView> createState() => _DiscoveryViewState();
}

class _DiscoveryViewState extends ConsumerState<DiscoveryView> {
  bool _hasShownMissingKeyWarning = false;
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  Future<void> _downloadTrack(SongEntity song) async {
    try {
      await ref.read(trackDownloadServiceProvider).downloadTrack(song);
      if (!mounted) return;
      ToastService.show(context, 'Downloaded ${song.title} to local library.');
    } catch (e) {
      if (!mounted) return;
      ToastService.show(
        context,
        'Failed to download ${song.title}.',
        backgroundColor: Colors.redAccent,
      );
    }
  }


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
    _searchController.dispose();
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
    ToastService.show(
      context,
      'JAMENDO_CLIENT_ID is empty in .env. Add your key to enable INSTALL.',
      backgroundColor: Colors.amber,
      duration: const Duration(seconds: 4),
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

    final jamendoResultsCount = 0; // Legacy placeholder
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
                    child: DiscoverySearchBar(
                      focusNode: _searchFocusNode,
                      controller: _searchController,
                      onSearchTriggered: _updateExistingDownloads,
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
                      child: ExcludeFocus(
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
                  ),
                ],
              ),
            ),
          ),

          
          // Result Body
          if (searchState.searchMode == SearchMode.spotifyImport)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: SpotifyImportPanel(),
            )
          else if (searchState.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Colors.white24)),
            )
          else if (searchState.results.isNotEmpty)
            DiscoveryResultsList(
              results: searchState.results,
              onDownload: _downloadTrack,
              onAddToPlaylist: _showAddToPlaylistDialog,
            )
          else if (searchState.error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: DiscoveryErrorState(error: searchState.error!),
            )
          else
            SliverToBoxAdapter(
              child: searchState.query.isNotEmpty 
                  ? const SizedBox(
                      height: 400,
                      child: Center(
                        child: Text('NO RESULTS FOUND', style: TextStyle(color: Colors.white12, letterSpacing: 2, fontSize: 10))
                      ),
                    )
                  : DiscoveryRecommendationsView(
                      onDownload: _downloadTrack,
                      onAddToPlaylist: _showAddToPlaylistDialog,
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
                        ToastService.show(context, 'Added to ${playlist.name}');
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


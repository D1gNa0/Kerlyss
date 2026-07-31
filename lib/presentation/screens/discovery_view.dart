import 'discovery_components/discovery_results_list.dart';
import 'discovery_components/spotify_import_panel.dart';
import 'discovery_components/spotify_pre_import_modal.dart';
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
import '../common/vercel_hover_button.dart';
import '../state/navigation_provider.dart';

import '../state/discovery_search_provider.dart';
import '../state/keyboard_shortcuts_provider.dart';
import '../../core/services/toast_service.dart';

import '../../data/repositories/repository_providers.dart';
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

    final songIds = searchState.results.map((s) => s.id).toList();
    final existingSongs = await isarService.getSongsByIds(songIds);

    final newAlreadyDownloaded = <String>{};
    for (final existing in existingSongs) {
      if (existing.localPath != null) {
        if (await File(existing.localPath!).exists()) {
          newAlreadyDownloaded.add(existing.songId);
        }
      }
    }

    if (mounted) {
      setState(() {
        ref.read(downloadStateProvider.notifier).setAlreadyDownloaded(newAlreadyDownloaded);
      });
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // Header — clean with top-left Home button
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
          
          // Search Input
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: DiscoverySearchBar(
                focusNode: _searchFocusNode,
                controller: _searchController,
                onSearchTriggered: _updateExistingDownloads,
              ),
            ),
          ),

          // Result Body
          if (RegExp(r'https?://open\.spotify\.com/playlist/[a-zA-Z0-9]+').hasMatch(searchState.query.trim()))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: SpotifyPreImportModal(spotifyUrl: searchState.query.trim()),
              ),
            )
          else if (searchState.searchMode == SearchMode.spotifyImport)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: SpotifyImportPanel(),
              ),
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
                        ref.read(playlistProvider.notifier).addSongToPlaylist(playlist.id!, song);
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


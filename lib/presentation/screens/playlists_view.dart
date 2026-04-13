import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/aether_colors.dart';
import '../state/playlist_provider.dart';
import '../common/aether_glass.dart';
import 'playlist_detail_view.dart';

class PlaylistsView extends ConsumerWidget {
  const PlaylistsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playlistProvider);

    return Scaffold(
      backgroundColor: AetherColors.deepMatteBlack,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.02),
              Colors.transparent,
            ],
          ),
        ),
        child: CustomScrollView(

        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            pinned: true,
            title: Text(
              'PLAYLISTS',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 14,
                    letterSpacing: 4,
                  ),
            ),
            centerTitle: true,
            actions: [
              TextButton.icon(
                onPressed: () => _showCreatePlaylistDialog(context, ref),
                icon: const Icon(Icons.add_rounded, color: AetherColors.primaryAccent, size: 20),
                label: const Text('CREATE', style: TextStyle(color: AetherColors.primaryAccent, fontSize: 11, letterSpacing: 1)),
              ),
              const SizedBox(width: 8),
            ],

          ),
          if (state.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Colors.white10)),
            )
          else if (state.playlists.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.playlist_add_rounded, color: Colors.white12, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'NO PLAYLISTS YET',
                      style: TextStyle(color: Colors.white24, letterSpacing: 2, fontSize: 10),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => _showCreatePlaylistDialog(context, ref),
                      child: const Text('CREATE YOUR FIRST', style: TextStyle(color: AetherColors.primaryAccent)),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              sliver: SliverList(

                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final playlist = state.playlists[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PlaylistTile(playlist: playlist),
                    );
                  },
                  childCount: state.playlists.length,
                ),
              ),
            ),

        ],
      ),
      ),
    );
  }


  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AetherColors.ultraDarkGray,
        title: const Text('NEW PLAYLIST', style: TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 2)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Playlist Name',
            hintStyle: TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AetherColors.primaryAccent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(playlistProvider.notifier).createPlaylist(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('CREATE', style: TextStyle(color: AetherColors.primaryAccent)),
          ),
        ],
      ),
    );
  }
}

class _PlaylistTile extends ConsumerWidget {
  final dynamic playlist;
  const _PlaylistTile({required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: Colors.white.withOpacity(0.03),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.playlist_play_rounded, color: Colors.white24),
      ),
      title: Text(
        playlist.name,
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${playlist.songIds.length} TRACKS',
        style: const TextStyle(color: AetherColors.textSecondary, fontSize: 11, letterSpacing: 1),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline_rounded, color: Colors.white24, size: 20),
        onPressed: () {
          ref.read(playlistProvider.notifier).deletePlaylist(playlist.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted ${playlist.name}'), backgroundColor: Colors.white12),
          );
        },
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaylistDetailView(playlist: playlist),
          ),
        );
      },
    );
  }
}


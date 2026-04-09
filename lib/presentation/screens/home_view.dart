import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../common/mini_player.dart';
import '../theme/aether_colors.dart';
import '../state/audio_provider.dart';
import '../state/audio_state.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AetherColors.deepMatteBlack,
      body: Stack(
        children: [
          // Background - Mesh Gradient effect refined for V4
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.8, -0.6),
                radius: 1.5,
                colors: [
                  Color(0x1AA855F7), // Very subtle purple
                  AetherColors.deepMatteBlack,
                ],
              ),
            ),
          ),
          
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // V4 Refined Header
              SliverAppBar(
                expandedHeight: 100,
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: IconButton(
                    onPressed: () {},
                    icon: CircleAvatar(
                      radius: 14,
                      backgroundColor: AetherColors.glassWhite,
                      child: const Icon(Icons.person_outline_rounded, size: 18, color: Colors.white),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    'KERLYSS',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.settings_outlined, size: 22, color: AetherColors.textSecondary),
                    ),
                  ),
                ],
              ),

              // V4 Category Switcher
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      _CategoryChip(label: 'ALL TRACKS', isActive: true),
                      const SizedBox(width: 24),
                      _CategoryChip(label: 'PLAYLISTS', isActive: false),
                      const SizedBox(width: 24),
                      _CategoryChip(label: 'FAVORITES', isActive: false),
                      const SizedBox(width: 24),
                      _CategoryChip(label: 'FOLDERS', isActive: false),
                    ],
                  ),
                ),
              ),

              // Track List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = SongMetadata(
                        id: 'song_$index',
                        title: 'Aether Track $index',
                        artist: 'Flux Architect',
                        duration: const Duration(minutes: 3, seconds: 45),
                        artworkUrl: 'https://picsum.photos/seed/${index+20}/400/400',
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          tileColor: Colors.white.withOpacity(0.02),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              song.artworkUrl!,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            song.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15),
                          ),
                          subtitle: Text(
                            song.artist,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.more_horiz_rounded, color: AetherColors.textSecondary, size: 18),
                          onTap: () {
                            ref.read(audioProvider.notifier).playSong(
                                  song,
                                  'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
                                );
                          },
                        ),
                      );
                    },
                    childCount: 15,
                  ),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),

          const Align(
            alignment: Alignment.bottomCenter,
            child: MiniPlayer(),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isActive;

  const _CategoryChip({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontSize: 11,
            color: isActive ? Colors.white : AetherColors.textSecondary,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
    );
  }
}

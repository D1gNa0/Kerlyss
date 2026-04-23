import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../common/aether_song_tile.dart';
import '../state/audio_provider.dart';
import '../state/audio_state.dart';
import '../common/aether_glass.dart';
import '../state/downloaded_songs_provider.dart';
import '../../domain/entities/audio_source_type.dart';
import '../../core/services/logger_service.dart';
import '../../core/services/toast_service.dart';

import '../state/library_provider.dart';
import '../../domain/entities/song_entity.dart';
import '../../data/models/playlist_model.dart';
import '../theme/aether_colors.dart';

class DownloadedSongsView extends ConsumerStatefulWidget {

  const DownloadedSongsView({super.key});

  @override
  ConsumerState<DownloadedSongsView> createState() => _DownloadedSongsViewState();
}

class _DownloadedSongsViewState extends ConsumerState<DownloadedSongsView> {
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    // Refresh the library every time the view is entered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(downloadedSongsProvider);
    });
  }

  Future<void> _handleDrop(DropDoneDetails detail) async {

    final localDownloadLibrary = ref.read(localDownloadLibraryProvider);
    var importedCount = 0;
    final failures = <String>[];

    for (final file in detail.files) {
      try {
        Log.i('Drop import requested: ${file.path}');
        await localDownloadLibrary.importFile(file.path);
        importedCount += 1;
      } catch (e) {
        failures.add('${file.path}: $e');
        Log.e('Drop import failed for ${file.path}: $e');
      }
    }

    if (!mounted) return;

    ref.invalidate(downloadedSongsProvider);

    if (importedCount > 0) {
      ToastService.show(context, 'Imported $importedCount file(s) to Downloads.');
    }

    if (failures.isNotEmpty) {
      ToastService.show(
        context,
        'Some files failed to import. Check log for details.',
        backgroundColor: Colors.redAccent,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloadedSongsAsync = ref.watch(downloadedSongsProvider);
    final localDownloadLibrary = ref.read(localDownloadLibraryProvider);
    final downloadsPathAsync = ref.watch(downloadedSongsPathProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            backgroundColor: Colors.transparent,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'DOWNLOADED SONGS',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontSize: 14,
                      letterSpacing: 6,
                      color: Colors.white38,
                    ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => ref.invalidate(downloadedSongsProvider),
                icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
                tooltip: 'Refresh downloads',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: DropTarget(
                onDragEntered: (_) => setState(() => _isDragging = true),
                onDragExited: (_) => setState(() => _isDragging = false),
                onDragDone: (detail) async {
                  setState(() => _isDragging = false);
                  await _handleDrop(detail);
                },
                child: SizedBox(
                  height: 130,
                  child: AetherGlass(
                    borderRadius: 20,
                    padding: const EdgeInsets.all(16),
                    child: DefaultTextStyle(
                      style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isDragging
                                ? 'Release to import into Downloads'
                                : 'Drop MP3, M4A, WAV, OGG, FLAC, or WEBM files here to import them into Kerlyss.',
                            style: TextStyle(
                              letterSpacing: 0.6,
                              color: _isDragging ? Colors.lightGreenAccent : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            downloadsPathAsync.maybeWhen(
                              data: (value) => 'Folder: $value',
                              orElse: () => 'Folder: %AppData%\\Kerlyss\\downloads',
                            ),
                            style: const TextStyle(color: Colors.white54),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          downloadedSongsAsync.when(
            data: (songs) {
              if (songs.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'NO DOWNLOADED FILES FOUND',
                      style: TextStyle(color: Colors.white24, letterSpacing: 2, fontSize: 10),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = songs[index];
                      final libraryState = ref.watch(libraryProvider);
                      // Find the song in the library that matches this local path
                      final libSong = libraryState.allSongs.firstWhere(
                        (s) => s.localPath == song.path,
                        orElse: () => SongEntity(
                          id: song.path,
                          title: song.title,
                          artist: 'Local File',
                          album: 'Downloads',
                          duration: Duration.zero,
                          sourceUrl: song.path,
                          sourceType: AudioSourceType.local,
                          dateAdded: song.modifiedAt,
                        ),
                      );

                      return AetherSongTile(
                        song: libSong,
                        onRemove: () async {
                          await localDownloadLibrary.deleteDownloadedSong(song.path);
                          ref.invalidate(downloadedSongsProvider);
                        },
                        onTap: () {
                          // Load all downloaded songs into the playlist
                          final playlist = songs.map((s) => SongMetadata(
                            id: s.path,
                            title: s.title,
                            artist: 'Local File',
                            album: 'Downloaded Songs',
                            duration: Duration.zero, // Resolved during playback
                            source: AudioSourceType.local,
                          )).toList();
                          
                          ref.read(audioProvider.notifier).playPlaylist(playlist, index);
                        },
                      );
                    },
                    childCount: songs.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator(color: Colors.white24)),
            ),
            error: (error, stackTrace) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'FAILED TO LOAD DOWNLOADS\n$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
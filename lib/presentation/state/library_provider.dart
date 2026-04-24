import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/song_entity.dart';
import '../../domain/repositories/song_repository.dart';
import '../../data/repositories/repository_providers.dart';
import '../../data/datasources/local/local_download_library.dart';
import '../../domain/entities/audio_source_type.dart';
import 'download_state_provider.dart';
import 'downloaded_songs_provider.dart';
import 'playlist_provider.dart';
import '../../core/services/logger_service.dart';

class LibraryState {
  final bool isLoading;
  final List<SongEntity> favoriteSongs;
  final List<SongEntity> allSongs;
  final Set<String> favoriteSongIds;

  const LibraryState({
    this.isLoading = false,
    this.favoriteSongs = const [],
    this.allSongs = const [],
    this.favoriteSongIds = const {},
  });
}

class LibraryNotifier extends StateNotifier<LibraryState> {
  final SongRepository _repository;
  final LocalDownloadLibrary _localDownloadLibrary;

  final Ref _ref;

  LibraryNotifier(this._repository, this._localDownloadLibrary, this._ref) : super(const LibraryState()) {
    loadLibrary();
    _listenToDownloads();
    _listenToPlaylists();
  }

  void _listenToDownloads() {
    _ref.listen<DownloadState>(downloadStateProvider, (previous, next) {
      if (previous == null) return;
      final previousIds = previous.alreadyDownloadedIds;
      final nextIds = next.alreadyDownloadedIds;
      final downloadSetChanged = previousIds.length != nextIds.length ||
          !previousIds.containsAll(nextIds) ||
          !nextIds.containsAll(previousIds);

      if (downloadSetChanged) {
        loadLibrary();
      }
    });
  }

  void _listenToPlaylists() {
    _ref.listen<PlaylistState>(playlistProvider, (previous, next) {
      if (previous == null) return;

      final previousSongIds = previous.playlists.expand((p) => p.songIds).toSet();
      final nextSongIds = next.playlists.expand((p) => p.songIds).toSet();
      final playlistSongsChanged = previousSongIds.length != nextSongIds.length ||
          !previousSongIds.containsAll(nextSongIds) ||
          !nextSongIds.containsAll(previousSongIds);

      // Only refresh the library when playlist membership changed, not when a playlist is renamed.
      if (playlistSongsChanged) {
        loadLibrary();
      }
    });
  }

  Future<void> loadLibrary() async {
    final isInitialLoad = state.favoriteSongs.isEmpty && state.allSongs.isEmpty;
    if (isInitialLoad) {
      state = LibraryState(isLoading: true, favoriteSongs: [], allSongs: []);
    }

    try {
      final favorites = await _repository.getFavorites();
      final all = await _repository.getAllSongs();
      
      // Also scan disk for anything that might not be in Isar (e.g. manually added files)
      final downloaded = await _localDownloadLibrary.listDownloadedSongs();
      // ─── FILTERING: Only include managed tracks in "All Tracks" ────────────────
      // A track is "managed" if it is a favorite or it is physically downloaded.
      final List<SongEntity> rawAll = List.from(all);
      
      // Sync disk files (same as before)
      final knownLocalPaths = all
          .where((song) => song.localPath != null)
          .map((song) => song.localPath!)
          .toSet();

      for (final diskSong in downloaded) {
        if (!knownLocalPaths.contains(diskSong.path)) {
          rawAll.add(SongEntity(
            id: diskSong.path,
            title: diskSong.title,
            artist: 'Local File',
            album: 'Downloads',
            duration: Duration.zero,
            sourceUrl: diskSong.path,
            sourceType: AudioSourceType.local,
            localPath: diskSong.path,
            dateAdded: diskSong.modifiedAt, // Use stable file date
          ));
        }
      }

      // FINAL FILTER: Only keep if it's a favorite, downloaded, OR in a playlist
      final favoriteIds = favorites.map((s) => s.id).toSet();
      final playlistSongIds = _ref.read(playlistProvider).playlists
          .expand((p) => p.songIds)
          .toSet();

      final filteredAll = rawAll.where((s) => 
        favoriteIds.contains(s.id) || 
        s.localPath != null || 
        playlistSongIds.contains(s.id)
      ).toList();

      // ─── STABLE SORTING: Date Added (Newest First) -> Title (A-Z) ───────────
      int stableSort(SongEntity a, SongEntity b) {
        final dateCompare = b.dateAdded.compareTo(a.dateAdded);
        if (dateCompare != 0) return dateCompare;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }

      filteredAll.sort(stableSort);
      final List<SongEntity> sortedFavorites = List.from(favorites)
        ..sort(stableSort);

      state = LibraryState(
        isLoading: false,
        favoriteSongs: sortedFavorites,
        allSongs: filteredAll,
        favoriteSongIds: sortedFavorites.map((song) => song.id).toSet(),
      );
    } catch (e) {
      state = LibraryState(
        isLoading: false,
        favoriteSongs: state.favoriteSongs,
        allSongs: state.allSongs,
        favoriteSongIds: state.favoriteSongIds,
      );
    }
  }

  Future<void> toggleFavorite(SongEntity song) async {
    final isFavorite = state.favoriteSongIds.contains(song.id);
    
    // ─── OPTIMISTIC UPDATE ────────────────────────────────────────────────────
    final updatedFavorites = List<SongEntity>.from(state.favoriteSongs);
    if (isFavorite) {
      updatedFavorites.removeWhere((s) => s.id == song.id);
    } else {
      updatedFavorites.add(song);
    }
    state = LibraryState(
      isLoading: false,
      favoriteSongs: updatedFavorites,
      allSongs: state.allSongs,
      favoriteSongIds: updatedFavorites.map((s) => s.id).toSet(),
    );
    // ───────────────────────────────────────────────────────────────────────────

    try {
      if (isFavorite) {
        await _repository.removeFromFavorites(song.id);
      } else {
        await _repository.addToFavorites(song);
      }
      // Silently refresh in background to ensure sync with DB
      await loadLibrary();
    } catch (e, stack) {
      Log.e('LibraryProvider: toggleFavorite ERROR: $e', e, stack);
      // Revert if failed (simple implementation: just reload)
      await loadLibrary();
    }
  }

  bool isSongFavorite(String id) {
    return state.favoriteSongIds.contains(id);
  }
}

final libraryProvider = StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  final repository = ref.watch(songRepositoryProvider);
  final localDownloadLibrary = ref.watch(localDownloadLibraryProvider);
  return LibraryNotifier(repository, localDownloadLibrary, ref);
});


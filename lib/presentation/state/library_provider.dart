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
  bool _isLoading = false;
  int _loadRequestId = 0;
  DateTime? _lastReloadTime;
  static const _minReloadInterval = Duration(seconds: 2);

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
        _debouncedLoadLibrary();
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

      if (playlistSongsChanged) {
        _debouncedLoadLibrary();
      }
    });
  }

  void _debouncedLoadLibrary() {
    final now = DateTime.now();
    if (_lastReloadTime != null && now.difference(_lastReloadTime!) < _minReloadInterval) {
      return;
    }
    _lastReloadTime = now;
    loadLibrary();
  }

  Future<void> loadLibrary() async {
    if (_isLoading) return;
    _isLoading = true;
    final requestId = ++_loadRequestId;

    final isInitialLoad = state.favoriteSongs.isEmpty && state.allSongs.isEmpty;
    if (isInitialLoad) {
      state = LibraryState(isLoading: true, favoriteSongs: [], allSongs: []);
    }

    try {
      final favorites = await _repository.getFavorites();
      final all = await _repository.getAllSongs();
      final downloaded = await _localDownloadLibrary.listDownloadedSongs();

      final favoriteIds = favorites.map((s) => s.id).toSet();
      final playlistSongIds = _ref.read(playlistProvider).playlists
          .expand((p) => p.songIds)
          .toSet();
      final knownLocalPaths = all
          .where((s) => s.localPath != null)
          .map((s) => s.localPath!)
          .toSet();

      final List<SongEntity> filteredAll = [];
      for (final song in all) {
        if (favoriteIds.contains(song.id) || song.localPath != null || playlistSongIds.contains(song.id)) {
          filteredAll.add(song);
        }
      }

      for (final diskSong in downloaded) {
        if (!knownLocalPaths.contains(diskSong.path) && playlistSongIds.contains(diskSong.path)) {
          filteredAll.add(SongEntity(
            id: diskSong.path,
            title: diskSong.title,
            artist: 'Local File',
            album: 'Downloads',
            duration: Duration.zero,
            sourceUrl: diskSong.path,
            sourceType: AudioSourceType.local,
            localPath: diskSong.path,
            dateAdded: diskSong.modifiedAt,
          ));
        }
      }

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
    } catch (e, stack) {
      Log.e('LibraryNotifier: loadLibrary failed: $e', e, stack);
      state = LibraryState(
        isLoading: false,
        favoriteSongs: state.favoriteSongs,
        allSongs: state.allSongs,
        favoriteSongIds: state.favoriteSongIds,
      );
    } finally {
      if (requestId == _loadRequestId) {
        _isLoading = false;
      }
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

  @override
  void dispose() {
    _isLoading = false;
    super.dispose();
  }
}

final libraryProvider = StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  final repository = ref.watch(songRepositoryProvider);
  final localDownloadLibrary = ref.watch(localDownloadLibraryProvider);
  return LibraryNotifier(repository, localDownloadLibrary, ref);
});


import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/song_entity.dart';
import '../../domain/repositories/song_repository.dart';
import '../../data/repositories/repository_providers.dart';
import '../../data/datasources/local/local_download_library.dart';
import '../../domain/entities/audio_source_type.dart';
import 'downloaded_songs_provider.dart';

class LibraryState {
  final bool isLoading;
  final List<SongEntity> favoriteSongs;
  final List<SongEntity> allSongs;

  const LibraryState({
    this.isLoading = false,
    this.favoriteSongs = const [],
    this.allSongs = const [],
  });
}

class LibraryNotifier extends StateNotifier<LibraryState> {
  final SongRepository _repository;
  final LocalDownloadLibrary _localDownloadLibrary;

  LibraryNotifier(this._repository, this._localDownloadLibrary) : super(const LibraryState()) {
    loadLibrary();
  }

  Future<void> loadLibrary() async {
    state = LibraryState(isLoading: true, favoriteSongs: state.favoriteSongs, allSongs: state.allSongs);
    try {
      final favorites = await _repository.getFavorites();
      final all = await _repository.getAllSongs();
      
      // Also scan disk for anything that might not be in Isar (e.g. manually added files)
      final downloaded = await _localDownloadLibrary.listDownloadedSongs();
      final List<SongEntity> syncedAll = List.from(all);
      
      for (final diskSong in downloaded) {
        final existsInIsar = all.any((s) => s.localPath == diskSong.path);
        if (!existsInIsar) {
          syncedAll.add(SongEntity(
            id: diskSong.path,
            title: diskSong.title,
            artist: 'Local File',
            album: 'Downloads',
            duration: Duration.zero,
            sourceUrl: diskSong.path,
            sourceType: AudioSourceType.local,
            localPath: diskSong.path,
          ));
        }
      }

      state = LibraryState(isLoading: false, favoriteSongs: favorites, allSongs: syncedAll);
    } catch (e) {
      state = LibraryState(isLoading: false, favoriteSongs: state.favoriteSongs, allSongs: state.allSongs);
    }
  }

  Future<void> toggleFavorite(SongEntity song) async {
    final isFavorite = state.favoriteSongs.any((s) => s.id == song.id);
    
    try {
      if (isFavorite) {
        await _repository.removeFromFavorites(song.id);
      } else {
        await _repository.addToFavorites(song);
      }
      // Refresh state from DB
      await loadLibrary();
    } catch (e) {
      // Allow soft fail
    }
  }

  bool isSongFavorite(String id) {
    return state.favoriteSongs.any((s) => s.id == id);
  }
}

final libraryProvider = StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  final repository = ref.watch(songRepositoryProvider);
  final localDownloadLibrary = ref.watch(localDownloadLibraryProvider);
  return LibraryNotifier(repository, localDownloadLibrary);
});


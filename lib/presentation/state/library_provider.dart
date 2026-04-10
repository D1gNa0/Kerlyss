import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/song_entity.dart';
import '../../domain/repositories/song_repository.dart';
import '../../data/repositories/repository_providers.dart';

class LibraryState {
  final bool isLoading;
  final List<SongEntity> favoriteSongs;

  const LibraryState({
    this.isLoading = false,
    this.favoriteSongs = const [],
  });
}

class LibraryNotifier extends StateNotifier<LibraryState> {
  final SongRepository _repository;

  LibraryNotifier(this._repository) : super(const LibraryState()) {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    state = const LibraryState(isLoading: true, favoriteSongs: []);
    try {
      final favorites = await _repository.getFavorites();
      state = LibraryState(isLoading: false, favoriteSongs: favorites);
    } catch (e) {
      state = const LibraryState(isLoading: false, favoriteSongs: []);
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
      await loadFavorites();
    } catch (e) {
      // Allow soft fail, usually log it
    }
  }

  bool isSongFavorite(String id) {
    return state.favoriteSongs.any((s) => s.id == id);
  }
}

final libraryProvider = StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  final repository = ref.watch(songRepositoryProvider);
  return LibraryNotifier(repository);
});

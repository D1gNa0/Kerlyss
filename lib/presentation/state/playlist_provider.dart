import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/playlist_entity.dart';
import '../../domain/entities/song_entity.dart';
import '../../domain/repositories/song_repository.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../../data/repositories/repository_providers.dart';
import '../../core/services/logger_service.dart';

class PlaylistState {
  final List<PlaylistEntity> playlists;
  final bool isLoading;

  const PlaylistState({
    this.playlists = const [],
    this.isLoading = false,
  });

  PlaylistState copyWith({
    List<PlaylistEntity>? playlists,
    bool? isLoading,
  }) {
    return PlaylistState(
      playlists: playlists ?? this.playlists,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PlaylistNotifier extends StateNotifier<PlaylistState> {
  final PlaylistRepository _playlistRepository;
  final SongRepository _songRepository;

  PlaylistNotifier(this._playlistRepository, this._songRepository) : super(const PlaylistState()) {
    loadPlaylists();
  }

  Future<void> loadPlaylists() async {
    try {
      state = state.copyWith(isLoading: true);
      final playlists = await _playlistRepository.getAllPlaylists();
      state = state.copyWith(playlists: playlists, isLoading: false);
    } catch (e, stack) {
      Log.e('PlaylistNotifier: loadPlaylists failed: $e', e, stack);
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> createPlaylist(String name) async {
    try {
      await _playlistRepository.createPlaylist(name, []);
      await loadPlaylists();
    } catch (e, stack) {
      Log.e('PlaylistNotifier: createPlaylist failed: $e', e, stack);
    }
  }

  Future<void> deletePlaylist(int id) async {
    try {
      await _playlistRepository.deletePlaylist(id);
      state = state.copyWith(
        playlists: state.playlists.where((playlist) => playlist.id != id).toList(),
      );
    } catch (e, stack) {
      Log.e('PlaylistNotifier: deletePlaylist failed: $e', e, stack);
    }
  }

  Future<void> renamePlaylist(int id, String newName) async {
    try {
      final playlist = await _playlistRepository.getPlaylistById(id);
      if (playlist != null) {
        final updated = playlist.copyWith(name: newName);
        await _playlistRepository.savePlaylist(updated);
        final updatedPlaylists = state.playlists.map((existing) {
          if (existing.id == id) {
            return updated;
          }
          return existing;
        }).toList();
        state = state.copyWith(playlists: updatedPlaylists);
      }
    } catch (e, stack) {
      Log.e('PlaylistNotifier: renamePlaylist failed: $e', e, stack);
    }
  }

  Future<void> addSongToPlaylist(int playlistId, SongEntity song) async {
    try {
      await _songRepository.saveSong(song);
      final playlist = await _playlistRepository.getPlaylistById(playlistId);
      if (playlist == null) return;

      if (!playlist.songIds.contains(song.id)) {
        final updatedIds = List<String>.from(playlist.songIds)..add(song.id);
        final updated = playlist.copyWith(songIds: updatedIds);
        await _playlistRepository.savePlaylist(updated);
        final updatedPlaylists = state.playlists.map((existing) {
          if (existing.id == playlistId) {
            return updated;
          }
          return existing;
        }).toList();
        state = state.copyWith(playlists: updatedPlaylists);
      }
    } catch (e, stack) {
      Log.e('PlaylistNotifier: addSongToPlaylist failed: $e', e, stack);
    }
  }

  Future<void> removeSongFromPlaylist(int playlistId, String songId) async {
    try {
      final playlist = await _playlistRepository.getPlaylistById(playlistId);
      if (playlist == null) return;

      final updatedIds = List<String>.from(playlist.songIds)..remove(songId);
      final updated = playlist.copyWith(songIds: updatedIds);
      await _playlistRepository.savePlaylist(updated);
      final updatedPlaylists = state.playlists.map((existing) {
        if (existing.id == playlistId) {
          return updated;
        }
        return existing;
      }).toList();
      state = state.copyWith(playlists: updatedPlaylists);
    } catch (e, stack) {
      Log.e('PlaylistNotifier: removeSongFromPlaylist failed: $e', e, stack);
    }
  }

  Future<List<SongEntity>> getPlaylistSongs(int playlistId) async {
    try {
      final playlist = await _playlistRepository.getPlaylistById(playlistId);
      if (playlist == null || playlist.songIds.isEmpty) return [];

      final songs = await _songRepository.getSongsByIds(playlist.songIds);
      return songs;
    } catch (e, stack) {
      Log.e('PlaylistNotifier: getPlaylistSongs failed: $e', e, stack);
      return [];
    }
  }
}

final playlistProvider = StateNotifierProvider<PlaylistNotifier, PlaylistState>((ref) {
  final repository = ref.watch(playlistRepositoryProvider);
  final songRepository = ref.watch(songRepositoryProvider);
  return PlaylistNotifier(repository, songRepository);
});

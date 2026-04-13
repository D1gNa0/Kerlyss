import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/playlist_model.dart';
import '../../domain/entities/song_entity.dart';
import '../../domain/repositories/song_repository.dart';
import '../../data/repositories/repository_providers.dart';
import '../../data/datasources/local/isar_database_service.dart';

class PlaylistState {
  final List<PlaylistModel> playlists;
  final bool isLoading;

  const PlaylistState({
    this.playlists = const [],
    this.isLoading = false,
  });

  PlaylistState copyWith({
    List<PlaylistModel>? playlists,
    bool? isLoading,
  }) {
    return PlaylistState(
      playlists: playlists ?? this.playlists,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PlaylistNotifier extends StateNotifier<PlaylistState> {
  final IsarDatabaseService _db;
  final SongRepository _songRepository;

  PlaylistNotifier(this._db, this._songRepository) : super(const PlaylistState()) {
    loadPlaylists();
  }

  Future<void> loadPlaylists() async {
    state = state.copyWith(isLoading: true);
    final playlists = await _db.getAllPlaylists();
    state = state.copyWith(playlists: playlists, isLoading: false);
  }

  Future<void> createPlaylist(String name) async {
    final playlist = PlaylistModel()..name = name..songIds = [];
    await _db.savePlaylist(playlist);
    await loadPlaylists();
  }

  Future<void> deletePlaylist(int id) async {
    await _db.deletePlaylist(id);
    await loadPlaylists();
  }

  Future<void> addSongToPlaylist(int playlistId, SongEntity song) async {
    // 1. Ensure metadata is saved (even if not downloaded/favorite)
    await _songRepository.saveSong(song);

    // 2. Fetch playlist
    final playlist = await _db.getPlaylistById(playlistId);
    if (playlist == null) return;

    // 3. Add ID if not already there
    if (!playlist.songIds.contains(song.id)) {
      final updatedIds = List<String>.from(playlist.songIds)..add(song.id);
      playlist.songIds = updatedIds;
      await _db.savePlaylist(playlist);
      await loadPlaylists();
    }
  }

  Future<void> removeSongFromPlaylist(int playlistId, String songId) async {
    final playlist = await _db.getPlaylistById(playlistId);
    if (playlist == null) return;

    final updatedIds = List<String>.from(playlist.songIds)..remove(songId);
    playlist.songIds = updatedIds;
    await _db.savePlaylist(playlist);
    await loadPlaylists();
  }

  /// Fetches the full SongEntity objects for a playlist.
  Future<List<SongEntity>> getPlaylistSongs(int playlistId) async {
    final playlist = await _db.getPlaylistById(playlistId);
    if (playlist == null) return [];

    final songs = <SongEntity>[];
    for (final id in playlist.songIds) {
      final song = await _songRepository.getSongById(id);
      if (song != null) {
        songs.add(song);
      }
    }
    return songs;
  }
}

final playlistProvider = StateNotifierProvider<PlaylistNotifier, PlaylistState>((ref) {
  final db = ref.watch(isarDatabaseServiceProvider);
  final repository = ref.watch(songRepositoryProvider);
  return PlaylistNotifier(db, repository);
});

import '../../core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/song_repository.dart';
import '../../data/repositories/repository_providers.dart';
import '../../domain/repositories/playlist_repository.dart';


enum ImportStatus { idle, analyzing, resolving, complete, error }

class ImportState {
  final ImportStatus status;
  final String playlistName;
  final int totalTracks;
  final int processedTracks;
  final List<String> failedTracks;
  final String? errorMessage;

  const ImportState({
    this.status = ImportStatus.idle,
    this.playlistName = '',
    this.totalTracks = 0,
    this.processedTracks = 0,
    this.failedTracks = const [],
    this.errorMessage,
  });

  ImportState copyWith({
    ImportStatus? status,
    String? playlistName,
    int? totalTracks,
    int? processedTracks,
    List<String>? failedTracks,
    String? errorMessage,
  }) {
    return ImportState(
      status: status ?? this.status,
      playlistName: playlistName ?? this.playlistName,
      totalTracks: totalTracks ?? this.totalTracks,
      processedTracks: processedTracks ?? this.processedTracks,
      failedTracks: failedTracks ?? this.failedTracks,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ImportStateNotifier extends StateNotifier<ImportState> {
  final SongRepository _repository;
  final PlaylistRepository _playlistRepo;

  ImportStateNotifier(this._repository, this._playlistRepo) : super(const ImportState());

  void setStatus(ImportStatus status, {String? errorMessage}) {
    state = state.copyWith(status: status, errorMessage: errorMessage);
  }

  void reset() {
    state = const ImportState();
  }

  Future<void> importSpotifyPlaylist(String url, bool download) async {
    if (url.isEmpty || !url.startsWith('http')) {
      setStatus(ImportStatus.error, errorMessage: 'Invalid URL.');
      return;
    }

    try {
      setStatus(ImportStatus.analyzing);

      final playlistData = await _repository.getPlaylistFromSpotifyUrl(url);

      final total = playlistData.trackQueries.length;
      if (total == 0) {
        setStatus(ImportStatus.error, errorMessage: 'No tracks found in playlist.');
        return;
      }

      state = ImportState(
        status: ImportStatus.resolving,
        playlistName: playlistData.name,
        totalTracks: total,
        processedTracks: 0,
        failedTracks: [],
      );

      final resolvedSongIds = <String>[];
      final newFailed = <String>[];

      // Process concurrently with a throttle buffer
      for (int i = 0; i < total; i += AppConstants.spotifyImportBatchSize) {
        final chunk = playlistData.trackQueries.skip(i).take(AppConstants.spotifyImportBatchSize).toList();

        final futures = chunk.map((query) async {

          try {
            final song = await _repository.resolveQueryToSong(query);
            if (song != null) {
              await _repository.saveSong(song);
              resolvedSongIds.add(song.id);
            } else {
              newFailed.add(query);
            }
          } catch (e) {
            newFailed.add(query);
          }

          if (mounted) {
            state = state.copyWith(processedTracks: state.processedTracks + 1);
          }
        });

        await Future.wait(futures);
      }

      if (mounted) {
        state = state.copyWith(failedTracks: newFailed);

        // Create the playlist in DB
        if (resolvedSongIds.isNotEmpty) {
          await _playlistRepo.createPlaylist(playlistData.name, resolvedSongIds);

          setStatus(ImportStatus.complete);
        } else {
          setStatus(ImportStatus.error, errorMessage: 'Failed to resolve any tracks.');
        }
      }
    } catch (e) {
      if (mounted) {
        setStatus(ImportStatus.error, errorMessage: 'Failed to import playlist: \${e.toString()}');
      }
    }
  }
}

final importStateProvider = StateNotifierProvider<ImportStateNotifier, ImportState>((ref) {
  final repository = ref.watch(songRepositoryProvider);
  final playlistRepo = ref.watch(playlistRepositoryProvider);
  return ImportStateNotifier(repository, playlistRepo);
});

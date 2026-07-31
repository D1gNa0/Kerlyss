import '../../core/services/logger_service.dart';
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
  Future<void> importSpotifyPlaylist(
    String url,
    bool download, {
    bool isRealtimeSynced = false,
    bool autoDownloadNewTracks = false,
  }) async {
    if (url.isEmpty || !url.startsWith('http')) {
      Log.w('Spotify Import: Invalid URL provided: $url');
      setStatus(ImportStatus.error, errorMessage: 'Invalid URL.');
      return;
    }

    try {
      Log.i('Spotify Import: Starting import for URL: $url');
      setStatus(ImportStatus.analyzing);

      final playlistData = await _repository.getPlaylistFromSpotifyUrl(url);
      Log.i('Spotify Import: Playlist analyzed. Name: "${playlistData.name}", Tracks: ${playlistData.trackQueries.length}');

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
      var processedCount = 0;

      // Process concurrently with a throttle buffer
      for (int i = 0; i < total; i += AppConstants.spotifyImportBatchSize) {
        final chunk = playlistData.trackQueries.skip(i).take(AppConstants.spotifyImportBatchSize).toList();

        await Future.wait(chunk.map((query) async {
          try {
            final song = await _repository.resolveQueryToSong(query);
            if (song != null) {
              await _repository.saveSong(song);
              resolvedSongIds.add(song.id);
            } else {
              newFailed.add(query);
            }
          } catch (e) {
            Log.w('ImportStateNotifier: Failed to resolve "$query": $e');
            newFailed.add(query);
          }
        }));

        processedCount += chunk.length;
        if (mounted) {
          state = state.copyWith(processedTracks: processedCount);
        }
      }

      if (mounted) {
        state = state.copyWith(failedTracks: newFailed);

        // Create the playlist in DB
        if (resolvedSongIds.isNotEmpty) {
          Log.i('Spotify Import: Creating playlist "${playlistData.name}" with ${resolvedSongIds.length} tracks (synced: $isRealtimeSynced)');
          await _playlistRepo.createPlaylist(
            playlistData.name,
            resolvedSongIds,
            isRealtimeSynced: isRealtimeSynced,
            autoDownloadNewTracks: autoDownloadNewTracks,
            spotifySourceUrl: url,
          );

          Log.i('Spotify Import: Successfully completed import of "${playlistData.name}"');
          setStatus(ImportStatus.complete);
        } else {
          Log.w('Spotify Import: Failed to resolve any tracks for "${playlistData.name}"');
          setStatus(ImportStatus.error, errorMessage: 'Failed to resolve any tracks.');
        }
      }
    } catch (e) {
      if (mounted) {
        Log.e('Spotify Import: Fatal error during import: ${e.toString()}');
        setStatus(ImportStatus.error, errorMessage: 'Failed to import playlist: ${e.toString()}');
      }
    }
  }
}

final importStateProvider = StateNotifierProvider<ImportStateNotifier, ImportState>((ref) {
  final repository = ref.watch(songRepositoryProvider);
  final playlistRepo = ref.watch(playlistRepositoryProvider);
  return ImportStateNotifier(repository, playlistRepo);
});

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/logger_service.dart';
import '../../core/services/app_storage_paths.dart';
import '../../data/datasources/remote/youtube_service.dart';
import '../../data/repositories/repository_providers.dart';
import '../../data/models/song_model.dart';
import '../../domain/entities/song_entity.dart';
import '../../domain/entities/audio_source_type.dart';
import 'download_state_provider.dart';
import 'downloaded_songs_provider.dart';
import 'library_provider.dart';

final trackDownloadServiceProvider = Provider((ref) => TrackDownloadService(ref));

class TrackDownloadService {
  final Ref ref;

  TrackDownloadService(this.ref);

  Future<void> downloadTrack(SongEntity song) async {
    final notifier = ref.read(downloadStateProvider.notifier);
    var didSucceed = false;
    
    if (ref.read(downloadStateProvider).downloadingTrackIds.contains(song.id)) {
      return;
    }

    notifier.setDownloading(song.id);

    try {
      String? destinationPath;

      if (song.sourceType == AudioSourceType.jamendo) {
        final jamendoService = ref.read(jamendoServiceProvider);
        final downloadedSong = await jamendoService.downloadTrack(song);
        destinationPath = downloadedSong.path;
      } else if (song.sourceType == AudioSourceType.youtube || song.sourceType == AudioSourceType.deezer) {
        final youtubeService = ref.read(youtubeServiceProvider);
        final downloadsDirectory = await AppStoragePaths.downloadsDirectory();

        // For Deezer tracks, find the matching YouTube video first using pristine metadata
        String videoId = song.id;
        if (song.sourceType == AudioSourceType.deezer) {
          Log.i('TrackDownload: Resolving Deezer track "${song.artist} - ${song.title}" to YouTube for download...');
          final results = await youtubeService.searchVideos('${song.artist} ${song.title}');
          if (results.isEmpty) throw Exception('No YouTube match found for Deezer track: ${song.title}');
          videoId = results.first.id.value;
          Log.i('TrackDownload: Found YouTube video $videoId for "${song.title}"');
        }

        destinationPath = YoutubeService.buildDestinationPath(
          downloadsDirectory.path,
          videoId,
          song.title, // Always use the clean Deezer title, not the YouTube video title
        );

        await youtubeService.downloadTrack(
          videoId,
          destinationPath,
          onProgress: (progress) {
            notifier.updateProgress(song.id, progress);
          },
        );
      }

      if (destinationPath != null) {
        // Persist in Isar
        final isarService = ref.read(isarDatabaseServiceProvider);
        await isarService.updateLocalPath(
          SongModel.fromEntity(song), 
          destinationPath,
        );

        // Sanity check: verify file exists
        if (await File(destinationPath).exists()) {
           // Update global "already downloaded" list
           final current = ref.read(downloadStateProvider).alreadyDownloadedIds;
           notifier.setAlreadyDownloaded({...current, song.id});
            didSucceed = true;
        }

        ref.invalidate(downloadedSongsProvider);
        Log.i('Download completed for ${song.id}: Saved to $destinationPath');
      }
    } catch (e) {
      Log.e('Download failed for ${song.id}: $e');
      rethrow;
    } finally {
      if (didSucceed) {
        notifier.completeDownload(song.id);
      } else {
        notifier.clearDownloadAttempt(song.id);
      }
    }
  }

  /// Downloads a list of songs sequentially.
  /// Skips already downloaded or currently downloading tracks.
  Future<void> downloadMultiple(List<SongEntity> songs) async {
    final notifier = ref.read(downloadStateProvider.notifier);
    final state = ref.read(downloadStateProvider);
    
    // Filter out songs that don't need downloading
    final toDownload = songs.where((song) {
      final isDownloading = state.downloadingTrackIds.contains(song.id);
      final isDownloaded = state.alreadyDownloadedIds.contains(song.id);
      return !isDownloading && !isDownloaded;
    }).toList();

    if (toDownload.isEmpty) {
      Log.i('Bulk download: No songs to download.');
      return;
    }

    Log.i('Bulk download: Starting sequential download for ${toDownload.length} songs.');
    notifier.startBulk(toDownload.length);
    
    for (final song in toDownload) {
      try {
        await downloadTrack(song);
      } catch (e) {
        Log.e('Bulk download: Failed for ${song.id}: $e');
        // Continue with next song despite error
      } finally {
        notifier.incrementBulk();
      }
    }
    
    Log.i('Bulk download: Finished.');
  }

  Future<void> deleteDownloadedTrack(SongEntity song) async {
    final notifier = ref.read(downloadStateProvider.notifier);
    try {
      String? pathToDelete = song.localPath;
      
      if (pathToDelete == null || !await File(pathToDelete).exists()) {
        final downloadsDirectory = await AppStoragePaths.downloadsDirectory();
        final idPart = '_${song.id.replaceAll('jamendo_', '')}';
        await for (final entity in downloadsDirectory.list(recursive: false)) {
          if (entity is File && entity.path.contains(idPart)) {
            pathToDelete = entity.path;
            break;
          }
        }
      }

      if (pathToDelete != null && await File(pathToDelete).exists()) {
        await File(pathToDelete).delete();
      }

      final isarService = ref.read(isarDatabaseServiceProvider);
      await isarService.updateLocalPath(SongModel.fromEntity(song), null);

      final current = ref.read(downloadStateProvider).alreadyDownloadedIds;
      final newSet = Set<String>.from(current)..remove(song.id);
      notifier.setAlreadyDownloaded(newSet);

      ref.invalidate(downloadedSongsProvider);
      ref.read(libraryProvider.notifier).loadLibrary();
      Log.i('Deleted download for ${song.id}');
    } catch (e) {
      Log.e('Failed to delete download for ${song.id}: $e');
    }
  }
}

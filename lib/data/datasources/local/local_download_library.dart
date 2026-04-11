import 'dart:io';
import 'package:path/path.dart' as p;

import '../../../core/services/app_storage_paths.dart';
import '../../../domain/entities/downloaded_song.dart';

class LocalDownloadLibrary {
  static const Set<String> _supportedExtensions = {
    '.mp3',
    '.m4a',
    '.aac',
    '.wav',
    '.ogg',
    '.flac',
    '.webm',
    '.mp4',
  };

  Future<List<DownloadedSong>> listDownloadedSongs() async {
    final downloadsDirectory = await AppStoragePaths.downloadsDirectory();

    final songs = <DownloadedSong>[];
    await for (final entity in downloadsDirectory.list(recursive: false, followLinks: false)) {
      if (entity is! File) {
        continue;
      }

      final extension = _fileExtension(entity.path);
      if (!_supportedExtensions.contains(extension)) {
        continue;
      }

      songs.add(await DownloadedSong.fromFile(entity));
    }

    songs.sort((left, right) => right.modifiedAt.compareTo(left.modifiedAt));
    return songs;
  }

  Future<DownloadedSong?> findDownloadedSongById(String id) async {
    final downloadsDirectory = await AppStoragePaths.downloadsDirectory();
    final idPart = '_$id';

    await for (final entity in downloadsDirectory.list(recursive: false)) {
      if (entity is! File) continue;

      final fileName = p.basename(entity.path);
      // Check if the filename contains the ID (youtube_ID_... or jamendo_ID_...)
      if (fileName.contains(idPart)) {
        return await DownloadedSong.fromFile(entity);
      }
    }
    return null;
  }

  Future<String> get downloadsPath async {

    return (await AppStoragePaths.downloadsDirectory()).path;
  }

  Future<DownloadedSong> importFile(String sourcePath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Source file does not exist', sourcePath);
    }

    final extension = _fileExtension(sourceFile.path);
    if (!_supportedExtensions.contains(extension)) {
      throw FileSystemException('Unsupported file type', sourcePath);
    }

    final downloadsDirectory = await AppStoragePaths.downloadsDirectory();
    final destinationPath = _uniqueDestinationPath(downloadsDirectory.path, p.basename(sourceFile.path));
    final copiedFile = await sourceFile.copy(destinationPath);
    return DownloadedSong.fromFile(copiedFile);
  }

  Future<void> deleteDownloadedSong(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  String _uniqueDestinationPath(String directoryPath, String originalFileName) {
    final baseName = p.basenameWithoutExtension(originalFileName);
    final extension = p.extension(originalFileName);
    final candidate = p.join(directoryPath, originalFileName);
    if (!File(candidate).existsSync()) {
      return candidate;
    }

    var suffix = 1;
    while (true) {
      final nextCandidate = p.join(directoryPath, '${baseName}_$suffix$extension');
      if (!File(nextCandidate).existsSync()) {
        return nextCandidate;
      }
      suffix += 1;
    }
  }

  static String _fileExtension(String path) {
    final fileName = path.split(Platform.pathSeparator).last;
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot < 0) {
      return '';
    }
    return fileName.substring(lastDot).toLowerCase();
  }
}
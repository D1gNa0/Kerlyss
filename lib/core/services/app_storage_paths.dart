import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AppStoragePaths {
  static const String appFolderName = 'Kerlyss';
  static const String downloadsFolderName = 'downloads';
  
  static Directory? _cachedAppRootDirectory;
  static Directory? _cachedDownloadsDirectory;
  static String? _customDownloadsPath;

  static String? get customDownloadsPath => _customDownloadsPath;

  static set customDownloadsPath(String? path) {
    _customDownloadsPath = path;
    _cachedDownloadsDirectory = null;
  }

  static Future<Directory> appRootDirectory() async {
    if (_cachedAppRootDirectory != null && await _cachedAppRootDirectory!.exists()) {
      return _cachedAppRootDirectory!;
    }
  
    final appDirectory = await _resolvePreferredAppDirectory();

    if (!await appDirectory.exists()) {
      await appDirectory.create(recursive: true);
    }

    _cachedAppRootDirectory = appDirectory;
    return appDirectory;
  }

  static Future<Directory> downloadsDirectory() async {
    if (_cachedDownloadsDirectory != null && await _cachedDownloadsDirectory!.exists()) {
      return _cachedDownloadsDirectory!;
    }
  
    if (_customDownloadsPath != null && _customDownloadsPath!.trim().isNotEmpty) {
      final customDir = Directory(_customDownloadsPath!);
      if (await customDir.exists()) {
        _cachedDownloadsDirectory = customDir;
        return customDir;
      }
    }

    final appDirectory = await appRootDirectory();
    final downloadsDirectory = Directory('${appDirectory.path}/$downloadsFolderName');

    if (!await downloadsDirectory.exists()) {
      await downloadsDirectory.create(recursive: true);
    }

    _cachedDownloadsDirectory = downloadsDirectory;
    return downloadsDirectory;
  }

  static Future<Directory> _resolvePreferredAppDirectory() async {
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null && appData.isNotEmpty) {
        return Directory('$appData\\$appFolderName');
      }
    }

    final baseDirectory = await getApplicationSupportDirectory();
    return Directory('${baseDirectory.path}/$appFolderName');
  }
}

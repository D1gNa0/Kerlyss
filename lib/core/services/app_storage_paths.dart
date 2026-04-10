import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AppStoragePaths {
  static const String appFolderName = 'Kerlyss';
  static const String downloadsFolderName = 'downloads';

  static Future<Directory> appRootDirectory() async {
    final appDirectory = await _resolvePreferredAppDirectory();

    if (!await appDirectory.exists()) {
      await appDirectory.create(recursive: true);
    }

    return appDirectory;
  }

  static Future<Directory> downloadsDirectory() async {
    final appDirectory = await appRootDirectory();
    final downloadsDirectory = Directory('${appDirectory.path}/$downloadsFolderName');

    if (!await downloadsDirectory.exists()) {
      await downloadsDirectory.create(recursive: true);
    }

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
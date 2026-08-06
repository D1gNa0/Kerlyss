import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerlyss/core/services/app_storage_paths.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppStoragePaths Dynamic Downloads Path', () {
    late Directory tempCustomDir;

    setUp(() async {
      AppStoragePaths.customDownloadsPath = null;
      tempCustomDir = await Directory.systemTemp.createTemp('kerlyss_custom_downloads_test');
    });

    tearDown(() async {
      AppStoragePaths.customDownloadsPath = null;
      if (await tempCustomDir.exists()) {
        await tempCustomDir.delete(recursive: true);
      }
    });

    test('returns custom downloads directory if customDownloadsPath is set and directory exists', () async {
      AppStoragePaths.customDownloadsPath = tempCustomDir.path;
      final dir = await AppStoragePaths.downloadsDirectory();
      expect(dir.path, equals(tempCustomDir.path));
    });

    test('falls back to default downloads directory if custom path does not exist', () async {
      final nonExistentPath = '${tempCustomDir.path}/non_existent_folder';
      AppStoragePaths.customDownloadsPath = nonExistentPath;

      final dir = await AppStoragePaths.downloadsDirectory();
      expect(dir.path, isNot(equals(nonExistentPath)));
      expect(dir.path.contains('downloads'), isTrue);
    });

    test('setting customDownloadsPath to null resets cached directory to default', () async {
      AppStoragePaths.customDownloadsPath = tempCustomDir.path;
      final customDirResult = await AppStoragePaths.downloadsDirectory();
      expect(customDirResult.path, equals(tempCustomDir.path));

      AppStoragePaths.customDownloadsPath = null;
      final defaultDirResult = await AppStoragePaths.downloadsDirectory();
      expect(defaultDirResult.path, isNot(equals(tempCustomDir.path)));
    });
  });
}

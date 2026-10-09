import 'package:flutter_test/flutter_test.dart';
import 'package:kerlyss/core/services/app_updater.dart';

void main() {
  group('AppUpdater.isNewerVersion', () {
    test('detects newer versions', () {
      expect(AppUpdater.isNewerVersion('1.3.4', '1.3.3'), isTrue);
      expect(AppUpdater.isNewerVersion('1.4.0', '1.3.9'), isTrue);
      expect(AppUpdater.isNewerVersion('2.0.0', '1.99.99'), isTrue);
      expect(AppUpdater.isNewerVersion('1.3.10', '1.3.9'), isTrue);
    });

    test('is false for same or older versions', () {
      expect(AppUpdater.isNewerVersion('1.3.3', '1.3.3'), isFalse);
      expect(AppUpdater.isNewerVersion('1.3.2', '1.3.3'), isFalse);
      expect(AppUpdater.isNewerVersion('1.3', '1.3.0'), isFalse);
    });

    test('handles v prefix, build numbers and different lengths', () {
      expect(AppUpdater.isNewerVersion('v1.3.4', '1.3.3+11'), isTrue);
      expect(AppUpdater.isNewerVersion('1.3.3.1', '1.3.3'), isTrue);
      expect(AppUpdater.isNewerVersion('1.3.3', '1.3.3+99'), isFalse);
    });
  });

  group('checksums.txt parsing', () {
    const sample = '''
Kerlyss Release Binary Checksums (SHA-256)
==============================================
Release Version: v1.3.2
Build Date: 2026-10-02

00C16BEB6C91AC729C56AF56363F6ECA5806A4E48DDD7BC09BAB4AB70F6986A7  Kerlyss-Android.apk
08DD765A2655D8BC62C47B72779BC9B9CE8BF6A70BE524F6F49CCB171F8F4273  Kerlyss-Windows.zip
''';

    test('reads release version', () {
      expect(AppUpdater.parseChecksumsVersion(sample), '1.3.2');
      expect(AppUpdater.parseChecksumsVersion('nothing here'), isNull);
    });

    test('reads hashes by file name (lower-cased)', () {
      final map = AppUpdater.parseChecksums(sample);
      expect(
        map['Kerlyss-Android.apk'],
        '00C16BEB6C91AC729C56AF56363F6ECA5806A4E48DDD7BC09BAB4AB70F6986A7'.toLowerCase(),
      );
      expect(
        map['Kerlyss-Windows.zip'],
        '08DD765A2655D8BC62C47B72779BC9B9CE8BF6A70BE524F6F49CCB171F8F4273'.toLowerCase(),
      );
      expect(map.length, 2);
    });
  });
}

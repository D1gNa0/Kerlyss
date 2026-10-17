import 'package:dio/dio.dart';
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

  group('AppUpdater.stripBom', () {
    test('removes a leading BOM and leaves normal text alone', () {
      expect(AppUpdater.stripBom('\uFEFF{"version":"1.0.0"}'), '{"version":"1.0.0"}');
      expect(AppUpdater.stripBom('{"version":"1.0.0"}'), '{"version":"1.0.0"}');
    });
  });

  group('AppUpdater pre-release (beta) versions', () {
    test('betas are ordered correctly', () {
      expect(AppUpdater.isNewerVersion('1.4.0-beta.2', '1.4.0-beta.1'), isTrue);
      expect(AppUpdater.isNewerVersion('1.4.0-beta.10', '1.4.0-beta.9'), isTrue);
      expect(AppUpdater.isNewerVersion('1.4.0-beta.1', '1.4.0-beta.2'), isFalse);
      expect(AppUpdater.isNewerVersion('1.4.0-beta.1', '1.4.0-beta.1'), isFalse);
    });

    test('a final release is newer than its betas, and a beta is newer than the previous stable', () {
      expect(AppUpdater.isNewerVersion('1.4.0', '1.4.0-beta.5'), isTrue);
      expect(AppUpdater.isNewerVersion('1.4.0-beta.5', '1.4.0'), isFalse);
      expect(AppUpdater.isNewerVersion('1.4.0-beta.1', '1.3.9'), isTrue);
      expect(AppUpdater.isNewerVersion('1.3.9', '1.4.0-beta.1'), isFalse);
    });

    test('build numbers are ignored, alpha < beta < rc', () {
      expect(AppUpdater.isNewerVersion('1.4.0-beta.2+20', '1.4.0-beta.1+25'), isTrue);
      expect(AppUpdater.isNewerVersion('1.4.0-beta.1', '1.4.0-alpha.9'), isTrue);
      expect(AppUpdater.isNewerVersion('1.4.0-rc.1', '1.4.0-beta.9'), isTrue);
    });

    test('isPrerelease', () {
      expect(AppUpdater.isPrerelease('1.4.0-beta.1'), isTrue);
      expect(AppUpdater.isPrerelease('1.4.0'), isFalse);
      expect(AppUpdater.isPrerelease('1.4.0+12'), isFalse);
    });

    test('beta download URL uses the exact pre-release tag, stable uses latest', () {
      const beta = UpdateInfo(
        version: '1.4.0-beta.1',
        notes: '',
        channel: UpdateChannel.beta,
        tag: 'v1.4.0-beta.1',
      );
      const stable = UpdateInfo(version: '1.4.0', notes: '');
      expect(AppUpdater.downloadUrlFor(beta), startsWith('https://github.com/D1gNa0/Kerlyss/releases/download/v1.4.0-beta.1/'));
      expect(AppUpdater.downloadUrlFor(stable), startsWith('https://github.com/D1gNa0/Kerlyss/releases/latest/download/'));
    });

    test('checksum file version can be a beta', () {
      expect(AppUpdater.parseChecksumsVersion('Release Version: v1.4.0-beta.1\nBuild Date: x'), '1.4.0-beta.1');
      expect(AppUpdater.parseChecksumsVersion('Release Version: v1.3.2\nBuild Date: x'), '1.3.2');
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

  group('AppUpdater network errors', () {
    DioException error(DioExceptionType type, {int? status, Object? inner}) {
      final request = RequestOptions(path: 'https://github.com/D1gNa0/Kerlyss/releases/download/v1/Kerlyss-Windows.zip');
      return DioException(
        requestOptions: request,
        type: type,
        error: inner,
        response: status == null ? null : Response<dynamic>(requestOptions: request, statusCode: status),
      );
    }

    test('user text says what happened', () {
      expect(AppUpdater.friendlyNetworkError(error(DioExceptionType.connectionTimeout)), contains('timed out'));
      expect(AppUpdater.friendlyNetworkError(error(DioExceptionType.receiveTimeout)), contains('timed out'));
      expect(AppUpdater.friendlyNetworkError(error(DioExceptionType.connectionError)), contains('Cannot reach GitHub'));
      expect(AppUpdater.friendlyNetworkError(error(DioExceptionType.badCertificate)), contains('certificate'));
      expect(AppUpdater.friendlyNetworkError(error(DioExceptionType.badResponse, status: 404)), contains('404'));
      expect(AppUpdater.friendlyNetworkError(error(DioExceptionType.badResponse, status: 403)), contains('403'));
      expect(AppUpdater.friendlyNetworkError(error(DioExceptionType.badResponse, status: 503)), contains('503'));
      expect(AppUpdater.friendlyNetworkError(error(DioExceptionType.unknown)), contains('interrupted'));
    });

    test('log text has type, status and host but no query', () {
      final text = AppUpdater.describeNetworkError(error(DioExceptionType.badResponse, status: 404, inner: 'oops'));
      expect(text, contains('type=badResponse'));
      expect(text, contains('status=404'));
      expect(text, contains('host=github.com'));
      expect(text, contains('error=oops'));
    });

    test('only network hiccups are retried', () {
      expect(AppUpdater.isRetryableNetworkError(error(DioExceptionType.connectionTimeout)), isTrue);
      expect(AppUpdater.isRetryableNetworkError(error(DioExceptionType.receiveTimeout)), isTrue);
      expect(AppUpdater.isRetryableNetworkError(error(DioExceptionType.connectionError)), isTrue);
      expect(AppUpdater.isRetryableNetworkError(error(DioExceptionType.unknown)), isTrue);
      expect(AppUpdater.isRetryableNetworkError(error(DioExceptionType.badResponse, status: 503)), isTrue);
      expect(AppUpdater.isRetryableNetworkError(error(DioExceptionType.badResponse, status: 429)), isTrue);
      expect(AppUpdater.isRetryableNetworkError(error(DioExceptionType.badResponse, status: 404)), isFalse);
      expect(AppUpdater.isRetryableNetworkError(error(DioExceptionType.badResponse, status: 403)), isFalse);
      expect(AppUpdater.isRetryableNetworkError(error(DioExceptionType.badCertificate)), isFalse);
      expect(AppUpdater.isRetryableNetworkError(error(DioExceptionType.cancel)), isFalse);
    });
  });
}

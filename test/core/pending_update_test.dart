import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kerlyss/core/services/pending_update.dart';

void main() {
  group('PendingUpdate', () {
    test('survives a JSON round trip', () {
      const original = PendingUpdate(
        version: '1.4.0-beta.1',
        path: r'C:\Users\me\AppData\Roaming\Kerlyss\update_staging\extracted',
        sha256: 'abc123',
        notes: 'Hello',
        isBeta: true,
        tag: 'v1.4.0-beta.1',
        attempts: 1,
      );

      final parsed = PendingUpdate.tryParse(_encode(original));

      expect(parsed, isNotNull);
      expect(parsed!.version, '1.4.0-beta.1');
      expect(parsed.path, original.path);
      expect(parsed.sha256, 'abc123');
      expect(parsed.notes, 'Hello');
      expect(parsed.isBeta, isTrue);
      expect(parsed.tag, 'v1.4.0-beta.1');
      expect(parsed.attempts, 1);
    });

    test('stable update has no tag and is not beta', () {
      const original = PendingUpdate(version: '1.4.0', path: '/tmp/x.apk', sha256: 'f00');
      final parsed = PendingUpdate.tryParse(_encode(original))!;
      expect(parsed.isBeta, isFalse);
      expect(parsed.tag, isNull);
      expect(parsed.attempts, 0);
    });

    test('bad input gives null and never throws', () {
      expect(PendingUpdate.tryParse(''), isNull);
      expect(PendingUpdate.tryParse('not json'), isNull);
      expect(PendingUpdate.tryParse('[]'), isNull);
      expect(PendingUpdate.tryParse('{}'), isNull);
      expect(PendingUpdate.tryParse('{"version":"1.0.0"}'), isNull);
      expect(PendingUpdate.tryParse('{"path":"/x"}'), isNull);
      expect(PendingUpdate.tryParse('{"version":"  ","path":"/x"}'), isNull);
    });

    test('copyWithAttempts only changes the attempt counter', () {
      const original = PendingUpdate(version: '1.4.0', path: '/p', sha256: 's', notes: 'n');
      final next = original.copyWithAttempts(2);
      expect(next.attempts, 2);
      expect(next.version, '1.4.0');
      expect(next.path, '/p');
      expect(next.sha256, 's');
      expect(next.notes, 'n');
    });
  });

  group('PendingUpdateStore', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('kerlyss_pending_update_test');
    });

    tearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('save, load and clear', () async {
      final store = PendingUpdateStore(directory: dir);
      expect(await store.load(), isNull);

      await store.save(const PendingUpdate(version: '1.5.0', path: '/p', sha256: 's'));
      final loaded = await store.load();
      expect(loaded?.version, '1.5.0');

      await store.clear();
      expect(await store.load(), isNull);
      // Clearing twice is fine.
      await store.clear();
    });

    test('a damaged file is treated as "nothing pending"', () async {
      final store = PendingUpdateStore(directory: dir);
      await File('${dir.path}${Platform.pathSeparator}${PendingUpdateStore.fileName}').writeAsString('{{{');
      expect(await store.load(), isNull);
    });
  });
}

String _encode(PendingUpdate update) => jsonEncode(update.toJson());

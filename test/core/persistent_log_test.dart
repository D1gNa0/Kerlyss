import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kerlyss/core/services/persistent_log.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('kerlyss_persistent_log_test');
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  PersistentLogFile make({int maxBytes = 256 * 1024}) =>
      PersistentLogFile(directory: () async => dir, maxBytes: maxBytes);

  File logFile() => File('${dir.path}${Platform.pathSeparator}kerlyss.log');

  group('format', () {
    test('one line with time and level', () {
      final text = PersistentLogFile.format('WARN', 'Something failed', now: DateTime(2026, 10, 17, 9, 5, 3));
      expect(text, '2026-10-17 09:05:03 WARN  Something failed\n');
    });

    test('error text is added and newlines are removed', () {
      final text = PersistentLogFile.format('ERROR', 'a\nb', error: 'boom\nbang', now: DateTime(2026, 1, 2, 3, 4, 5));
      expect(text.trimRight().contains('\n'), isFalse);
      expect(text, contains('a b'));
      expect(text, contains('boom bang'));
    });

    test('personal data is removed', () {
      final text = PersistentLogFile.format(
        'ERROR',
        r'failed at C:\Users\Kerem Arslan\AppData\x for me@example.com ip 192.168.1.20',
        now: DateTime(2026, 1, 1),
      );
      expect(text, isNot(contains('Kerem')));
      expect(text, isNot(contains('me@example.com')));
      expect(text, isNot(contains('192.168.1.20')));
    });

    test('stack trace is limited to 6 lines', () {
      final stack = StackTrace.fromString(List.generate(20, (i) => '#$i frame').join('\n'));
      final text = PersistentLogFile.format('ERROR', 'x', stackTrace: stack, now: DateTime(2026, 1, 1));
      expect('\n'.allMatches(text).length, 1 + 6); // message line + 6 stack lines
    });
  });

  group('file', () {
    test('lines are appended in order', () async {
      final log = make();
      log.write('INFO', 'first');
      log.write('WARN', 'second');
      await log.flush();
      final lines = await logFile().readAsLines();
      expect(lines.length, 2);
      expect(lines[0], contains('first'));
      expect(lines[1], contains('second'));
    });

    test('a full file becomes kerlyss.log.old and a new file starts', () async {
      final log = make(maxBytes: 300);
      for (var i = 0; i < 20; i++) {
        log.write('INFO', 'line number $i with some padding text');
      }
      await log.flush();

      expect(await File('${logFile().path}.old').exists(), isTrue);
      expect(await logFile().length(), lessThanOrEqualTo(300));
      // The newest line is in the current file.
      expect(await logFile().readAsString(), contains('line number 19'));
    });

    test('an already big file is rotated when the app starts', () async {
      await logFile().writeAsString('x' * 1000);
      final log = make(maxBytes: 500);
      log.write('INFO', 'after start');
      await log.flush();

      expect(await File('${logFile().path}.old').exists(), isTrue);
      expect(await logFile().readAsString(), contains('after start'));
      expect(await logFile().readAsString(), isNot(contains('xxxx')));
    });

    test('tail returns the newest lines, oldest first', () async {
      final log = make();
      for (var i = 0; i < 10; i++) {
        log.write('INFO', 'entry $i');
      }
      final lines = await log.tail(3);
      expect(lines.length, 3);
      expect(lines[0], contains('entry 7'));
      expect(lines[2], contains('entry 9'));
    });

    test('tail continues into kerlyss.log.old after a rotation', () async {
      final log = make(maxBytes: 200);
      for (var i = 0; i < 12; i++) {
        log.write('INFO', 'rotating entry $i');
      }
      final lines = await log.tail(5);
      expect(lines.length, 5);
      expect(lines.last, contains('rotating entry 11'));
      expect(lines.first, contains('rotating entry 7'));
    });

    test('tail of a missing file is empty', () async {
      expect(await make().tail(10), isEmpty);
      expect(await PersistentLogFile.tailOf(File('${dir.path}${Platform.pathSeparator}nope.log'), 5), isEmpty);
    });

    test('writing to a missing disk never throws', () async {
      final log = PersistentLogFile(directory: () async => throw const FileSystemException('no disk'));
      log.write('ERROR', 'cannot be saved');
      await log.flush(); // completes normally
    });
  });
}

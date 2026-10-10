import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kerlyss/core/services/error_reporter.dart';
import 'package:kerlyss/core/services/log_buffer.dart';
import 'package:logger/logger.dart' show Level;

void main() {
  group('ErrorReporter.isNoise', () {
    test('network and layout errors are noise', () {
      expect(ErrorReporter.isNoise(const SocketException('Failed host lookup: x')), isTrue);
      expect(ErrorReporter.isNoise('A RenderFlex overflowed by 12 pixels'), isTrue);
      expect(ErrorReporter.isNoise(Exception('Connection closed before full header was received')), isTrue);
    });

    test('environment and lifecycle errors are noise', () {
      expect(ErrorReporter.isNoise('PathAccessException: Access is denied, path = C:\\x'), isTrue);
      expect(ErrorReporter.isNoise('FileSystemException: No space left on device'), isTrue);
      expect(ErrorReporter.isNoise('setState() called after dispose(): _FooState'), isTrue);
    });

    test('real bugs are not noise', () {
      expect(ErrorReporter.isNoise(StateError('Bad state: No element')), isFalse);
      expect(ErrorReporter.isNoise(ArgumentError('nope')), isFalse);
    });
  });

  group('report building', () {
    final logs = List.generate(200, (i) => '[00:00:${i % 60}] INFO: line $i from kerem@example.com');

    test('report is sanitized and fences are escaped', () {
      final report = ErrorReporter.composeReport(
        environment: r'Kerlyss 1.3.3 | windows | C:\Users\kerem',
        kind: 'test',
        note: 'mail me at a@b.com',
        error: 'boom ``` inside',
        stack: '#0 main',
        logs: logs.take(3).toList(),
      );
      expect(report, isNot(contains('kerem@example.com')));
      expect(report, isNot(contains('a@b.com')));
      expect(report, isNot(contains(r'Users\kerem')));
      expect(report, contains('<email>'));
      expect(report, contains("boom ''' inside"));
    });

    test('issue URL always fits the length limit and keeps the title', () {
      final uri = ErrorReporter.composeIssueUri(
        title: '[Auto report] test: boom',
        environment: 'Kerlyss 1.3.3 | windows',
        kind: 'test',
        error: 'E' * 2000,
        stack: List.generate(40, (i) => '#$i frame').join('\n'),
        logs: logs,
        maxUrlLength: 6000,
      );
      expect(uri.toString().length, lessThanOrEqualTo(6000));
      expect(uri.queryParameters['title'], '[Auto report] test: boom');
      expect(uri.toString(), startsWith('https://github.com/D1gNa0/Kerlyss/issues/new'));
    });
  });

  group('LogBuffer', () {
    test('keeps only the newest entries and skips debug', () {
      LogBuffer.instance.clear();
      LogBuffer.instance.add(Level.debug, 'ignored');
      for (var i = 0; i < LogBuffer.maxEntries + 50; i++) {
        LogBuffer.instance.add(Level.info, 'msg $i');
      }
      final all = LogBuffer.instance.recent(1000);
      expect(all.length, LogBuffer.maxEntries);
      expect(all.last, contains('msg ${LogBuffer.maxEntries + 49}'));
      expect(all.any((l) => l.contains('ignored')), isFalse);
      LogBuffer.instance.clear();
    });
  });
}

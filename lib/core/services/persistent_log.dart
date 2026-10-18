import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'log_sanitizer.dart';

/// The log FILE of the app (`kerlyss.log`). It is written in EVERY build mode, release too,
/// so a problem on a user's PC can be diagnosed afterwards.
///
/// Only things worth keeping are written here (warnings, errors and a few key events,
/// see `Log` in logger_service.dart), so the file stays small and readable.
///  * Personal data (user name in paths, e-mails, tokens, IPs, URL parameters) is removed
///    with [LogSanitizer] before anything is written.
///  * Size is capped: when the file is full it becomes `kerlyss.log.old` (the previous
///    `.old` is replaced), so at most about 2 x [maxBytes] are ever used.
///  * Writing can never throw or block the app: lines are queued and a failing disk is
///    ignored (after 5 failures in a row the file is switched off for this session).
class PersistentLogFile {
  PersistentLogFile({
    required Future<Directory> Function() directory,
    this.maxBytes = 256 * 1024,
    String fileName = 'kerlyss.log',
  })  : _directory = directory,
        _fileName = fileName;

  final Future<Directory> Function() _directory;
  final String _fileName;

  /// When the file would grow past this size it is rotated.
  final int maxBytes;

  Future<void> _chain = Future<void>.value();
  File? _file;
  int _bytes = 0;
  int _failures = 0;
  bool _disabled = false;

  /// Queues one line (plus a short stack trace for errors). Returns immediately.
  void write(
    String level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    DateTime? now,
  }) {
    if (_disabled) return;
    final text = format(level, message, error: error, stackTrace: stackTrace, now: now ?? DateTime.now());
    _chain = _chain.then((_) => _append(text)).then<void>((_) {}, onError: (Object _) {});
  }

  /// Completes when everything queued so far is on disk (used by tests).
  Future<void> flush() => _chain;

  /// The newest [count] lines (oldest first). Reads `kerlyss.log.old` too when the
  /// current file is short (right after a rotation). Never throws.
  Future<List<String>> tail(int count) async {
    try {
      await flush();
      final dir = await _directory();
      final lines = await tailOf(File(p.join(dir.path, _fileName)), count);
      if (lines.length < count) {
        final older = await tailOf(File(p.join(dir.path, '$_fileName.old')), count - lines.length);
        return [...older, ...lines];
      }
      return lines;
    } catch (_) {
      return const [];
    }
  }

  /// The last [count] lines of any text file (empty list when it is missing or unreadable).
  static Future<List<String>> tailOf(File file, int count) async {
    try {
      if (count <= 0 || !await file.exists()) return const [];
      final text = utf8.decode(await file.readAsBytes(), allowMalformed: true);
      final lines = const LineSplitter().convert(text).where((l) => l.trim().isNotEmpty).toList();
      return lines.length <= count ? lines : lines.sublist(lines.length - count);
    } catch (_) {
      return const [];
    }
  }

  /// `2026-10-17 20:14:03 WARN  message | error` (+ up to 6 indented stack lines).
  /// The result is already sanitized and ends with a newline.
  static String format(
    String level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    required DateTime now,
  }) {
    final buffer = StringBuffer('${_stamp(now)} ${level.padRight(5)} ${_clip(message, 600)}');
    if (error != null) buffer.write(' | ${_clip(error.toString(), 400)}');
    var text = buffer.toString().replaceAll('\r', ' ').replaceAll('\n', ' ');

    if (stackTrace != null) {
      final top = stackTrace
          .toString()
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .take(6)
          .map((l) => '    $l')
          .join('\n');
      if (top.isNotEmpty) text = '$text\n$top';
    }
    return '${LogSanitizer.sanitize(text)}\n';
  }

  Future<void> _append(String text) async {
    if (_disabled) return;
    try {
      var file = _file;
      if (file == null) {
        final dir = await _directory();
        await dir.create(recursive: true);
        file = File(p.join(dir.path, _fileName));
        if (await file.exists() && await file.length() >= maxBytes) await _rotate(file);
        _bytes = await file.exists() ? await file.length() : 0;
        _file = file;
      }
      if (_bytes > 0 && _bytes + text.length > maxBytes) {
        await _rotate(file);
        _bytes = 0;
      }
      await file.writeAsString(text, mode: FileMode.append, flush: true);
      _bytes += text.length;
      _failures = 0;
    } catch (_) {
      _failures++;
      if (_failures >= 5) _disabled = true;
      rethrow; // swallowed by the queue in write(); the log must never break the app
    }
  }

  Future<void> _rotate(File file) async {
    final old = File('${file.path}.old');
    try {
      if (await old.exists()) await old.delete();
    } catch (_) {}
    try {
      if (await file.exists()) await file.rename(old.path);
    } catch (_) {
      try {
        await file.delete();
      } catch (_) {}
    }
  }

  static String _stamp(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }

  static String _clip(String s, int max) => s.length > max ? '${s.substring(0, max)}...' : s;
}

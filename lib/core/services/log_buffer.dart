import 'dart:collection';

import 'package:logger/logger.dart' show Level;

/// Keeps the last few hundred log lines IN MEMORY, in every build mode.
///
/// The normal [Log] output is switched off in release builds (no console, no file),
/// so without this buffer an error report would contain no log lines at all.
/// Nothing here is ever written to disk or sent anywhere by itself; it is only read
/// when the user chooses to report a problem (and it is sanitized first).
class LogBuffer {
  LogBuffer._();
  static final LogBuffer instance = LogBuffer._();

  static const int maxEntries = 400;
  static const int _maxMessageLength = 500;
  static const int _maxErrorLength = 300;

  final Queue<String> _lines = Queue<String>();

  void add(Level level, dynamic message, [dynamic error, StackTrace? stackTrace]) {
    // Only info and above (debug/trace are too noisy and not useful in a report).
    if (level.index < Level.info.index) return;

    final label = switch (level) {
      Level.warning => 'WARN',
      Level.error => 'ERROR',
      Level.fatal => 'FATAL',
      _ => 'INFO',
    };
    final now = DateTime.now();
    final time = '${_two(now.hour)}:${_two(now.minute)}:${_two(now.second)}';

    final buffer = StringBuffer('[$time] $label: ${_truncate(message.toString(), _maxMessageLength)}');
    if (error != null) {
      buffer.write(' | ${_truncate(error.toString(), _maxErrorLength)}');
    }
    if (stackTrace != null && level.index >= Level.error.index) {
      final top = stackTrace.toString().split('\n').take(4).join(' <- ');
      buffer.write(' | stack: ${_truncate(top, _maxErrorLength)}');
    }

    _lines.addLast(buffer.toString().replaceAll('\n', ' '));
    while (_lines.length > maxEntries) {
      _lines.removeFirst();
    }
  }

  /// The newest [count] lines, oldest first.
  List<String> recent([int count = 120]) {
    final all = _lines.toList();
    return all.length <= count ? all : all.sublist(all.length - count);
  }

  void clear() => _lines.clear();

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _truncate(String s, int max) => s.length > max ? '${s.substring(0, max)}...' : s;
}

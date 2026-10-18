import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../presentation/common/error_report_dialog.dart';
import 'app_storage_paths.dart';
import 'log_buffer.dart';
import 'log_sanitizer.dart';
import 'logger_service.dart';
import 'persistent_log.dart';

/// Lets the error reporter show a dialog without needing a BuildContext.
/// Must be passed to `MaterialApp(navigatorKey: rootNavigatorKey)`.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// What we know about one problem. Contains NO logs yet; those are added (and
/// sanitized) when the report text is built.
class ErrorReportDraft {
  final String kind; // short machine-friendly label, e.g. 'playback-repeated-failure'
  final String userMessage; // friendly sentence shown in the dialog
  final String errorText;
  final String stackText;
  final bool manual;

  const ErrorReportDraft({
    required this.kind,
    required this.userMessage,
    this.errorText = '',
    this.stackText = '',
    this.manual = false,
  });
}

/// "Report this error" flow (Option A): we never send anything ourselves. When the
/// user agrees we open a PRE-FILLED GitHub issue in their browser (and copy the full
/// report to the clipboard). No token, no server, nothing to secure.
class ErrorReporter {
  ErrorReporter._();
  static final ErrorReporter instance = ErrorReporter._();

  static const String issuesNewUrl = 'https://github.com/D1gNa0/Kerlyss/issues/new';

  /// Debug builds log errors but do not pop up the dialog (it would be noise while developing).
  @visibleForTesting
  static bool promptInDebug = false;

  static const int _maxPromptsPerSession = 3;
  static const Duration _minGapBetweenPrompts = Duration(minutes: 2);

  final Set<String> _seenSignatures = <String>{};
  bool _dialogOpen = false;
  int _promptCount = 0;
  DateTime? _lastPromptAt;
  bool _installed = false;
  bool _handlingError = false;

  // ───────────────────────── global handlers ─────────────────────────

  /// Call once from `main()` (before `runApp`).
  void install() {
    if (_installed) return;
    _installed = true;

    final previousFlutterHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      previousFlutterHandler?.call(details); // keep the default console output
      handleError(details.exception, details.stack, source: 'flutter');
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      handleError(error, stack, source: 'async');
      return true; // handled
    };
  }

  /// Logs an uncaught error and, if it looks like a real bug, offers to report it.
  void handleError(Object error, StackTrace? stack, {required String source}) {
    // Guard: if logging or the dialog itself throws, do not handle that error again forever.
    if (_handlingError) return;
    _handlingError = true;
    try {
      try {
        Log.e('Unhandled $source error', error, stack);
      } catch (_) {}

      if (isNoise(error)) return;

      reportLethal(
        kind: 'unhandled-$source',
        userMessage: 'Kerlyss ran into an unexpected problem.',
        error: error,
        stack: stack,
      );
    } finally {
      _handlingError = false;
    }
  }

  /// Errors that are NOT bugs in the app (bad network, layout overflow in one frame,
  /// cancelled requests, ...). They must never trigger a "report?" dialog.
  static bool isNoise(Object error) {
    final type = error.runtimeType.toString();
    final text = error.toString();
    const noisyTypes = [
      'SocketException',
      'HandshakeException',
      'HttpException',
      'TimeoutException',
      'DioException',
      'ClientException',
      'PlayerInterruptedException',
      'NetworkImageLoadException',
      'WebSocketException',
    ];
    if (noisyTypes.any(type.contains)) return true;

    const noisyText = [
      // Environment problems, not bugs in Kerlyss
      'Access is denied',
      'No space left on device',
      'not enough space on the disk',
      'errno = 28',
      // Harmless Flutter/Riverpod lifecycle errors (worth fixing, not worth asking the user)
      'setState() called after dispose',
      "deactivated widget's ancestor",
      'was called after dispose',
      'after `dispose` was called',
      'RenderFlex overflowed',
      'overflowed by',
      'Failed host lookup',
      'Connection closed',
      'Connection reset',
      'Connection refused',
      'Connection timed out',
      'Software caused connection abort',
      'Loading interrupted',
      'Connection aborted',
      'HTTP request failed',
      'Network is unreachable',
    ];
    return noisyText.any(text.contains);
  }

  // ───────────────────────── asking the user ─────────────────────────

  /// Ask the user whether to report [error]. Rate limited: once per distinct error per
  /// session, max 3 prompts per session, at least 2 minutes apart, never while a
  /// dialog is already open, and never if the user chose "Don't ask again".
  void reportLethal({
    required String kind,
    required String userMessage,
    required Object error,
    StackTrace? stack,
  }) {
    if (kDebugMode && !promptInDebug) {
      Log.d('ErrorReporter: would ask to report "$kind" (suppressed in debug): $error');
      return;
    }

    final firstLine = error.toString().split('\n').first;
    final signature = '$kind|${error.runtimeType}|${firstLine.length > 120 ? firstLine.substring(0, 120) : firstLine}';
    if (!_seenSignatures.add(signature)) return;
    if (_dialogOpen || _promptCount >= _maxPromptsPerSession) return;

    final last = _lastPromptAt;
    if (last != null && DateTime.now().difference(last) < _minGapBetweenPrompts) return;

    _promptCount++;
    _lastPromptAt = DateTime.now();

    final draft = ErrorReportDraft(
      kind: kind,
      userMessage: userMessage,
      errorText: _clip(error.toString(), 600),
      stackText: stack == null ? '' : stack.toString().split('\n').take(15).join('\n'),
    );
    unawaited(_prompt(draft));
  }

  Future<void> _prompt(ErrorReportDraft draft) async {
    if (!await isAskEnabled()) return;

    _dialogOpen = true;
    try {
      // The navigator may not exist yet (very early error). Retry for a few seconds.
      BuildContext? context;
      for (var i = 0; i < 8; i++) {
        context = rootNavigatorKey.currentContext;
        if (context != null && rootNavigatorKey.currentState?.overlay != null) break;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      if (context == null || !context.mounted) return;
      await showErrorReportDialog(context, draft);
    } catch (e) {
      Log.w('ErrorReporter: could not show the report dialog: $e');
    } finally {
      _dialogOpen = false;
    }
  }

  /// Draft for the "Report a Problem" button in Settings (no specific error).
  ErrorReportDraft manualDraft() => const ErrorReportDraft(
        kind: 'manual',
        userMessage: 'Tell us what went wrong. A sanitized copy of the recent log is included to help us fix it.',
        manual: true,
      );

  // ───────────────────────── preference ─────────────────────────

  Future<File?> _prefsFile() async {
    try {
      final dir = await AppStoragePaths.appRootDirectory();
      return File('${dir.path}/error_reporting.json');
    } catch (_) {
      return null;
    }
  }

  Future<bool> isAskEnabled() async {
    try {
      final file = await _prefsFile();
      if (file == null || !await file.exists()) return true;
      final data = jsonDecode(await file.readAsString());
      return data is Map ? data['ask'] != false : true;
    } catch (_) {
      return true;
    }
  }

  Future<void> setAskEnabled(bool value) async {
    try {
      final file = await _prefsFile();
      await file?.writeAsString(jsonEncode({'ask': value}));
    } catch (_) {}
  }

  // ───────────────────────── building the report ─────────────────────────

  Future<String> _environment() async {
    String version = '?';
    try {
      final info = await PackageInfo.fromPlatform();
      version = '${info.version} (${info.buildNumber})';
    } catch (_) {}
    final os = LogSanitizer.sanitize(Platform.operatingSystemVersion);
    return 'Kerlyss $version | ${Platform.operatingSystem} | $os | locale ${PlatformDispatcher.instance.locale}';
  }

  /// Log lines for a report:
  ///  * `kerlyss.log` (warnings, errors, key events). It survives app restarts, so it also
  ///    holds what happened in an earlier session, for example an update that was installed
  ///    while the app was closing.
  ///  * the end of `update.log` (written by the Windows updater script), if it exists.
  /// When the file has nothing yet, the in-memory buffer of this session is used instead.
  Future<List<String>> _recentLogs(int count, {int updateScriptLines = 15}) async {
    var lines = await Log.recentFileLines(count);
    if (lines.isEmpty) lines = LogBuffer.instance.recent(count);

    var script = const <String>[];
    try {
      final dir = await AppStoragePaths.appRootDirectory();
      script = await PersistentLogFile.tailOf(File('${dir.path}/update.log'), updateScriptLines);
    } catch (_) {}

    if (script.isEmpty) return lines;
    return [...lines, '--- update.log (Windows updater script) ---', ...script];
  }

  /// Full sanitized report (what the dialog previews and what goes to the clipboard).
  Future<String> buildReport(ErrorReportDraft draft, {String? note, int logLines = 120}) async {
    return composeReport(
      environment: await _environment(),
      kind: draft.kind,
      note: note,
      error: draft.errorText,
      stack: draft.stackText,
      logs: await _recentLogs(logLines),
    );
  }

  Future<Uri> buildIssueUri(ErrorReportDraft draft, {String? note}) async {
    return composeIssueUri(
      title: draft.manual
          ? '[Report] Problem report'
          : '[Auto report] ${draft.kind}: ${_clip(draft.errorText.split('\n').first, 70)}',
      environment: await _environment(),
      kind: draft.kind,
      note: note,
      error: draft.errorText,
      stack: draft.stackText,
      logs: await _recentLogs(60),
    );
  }

  /// Copies the full report to the clipboard and opens the pre-filled issue page.
  /// Returns false if the browser could not be opened (report is still on the clipboard).
  Future<bool> openIssue(ErrorReportDraft draft, {String? note}) async {
    await Clipboard.setData(ClipboardData(text: await buildReport(draft, note: note)));
    final uri = await buildIssueUri(draft, note: note);
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<void> copyReport(ErrorReportDraft draft, {String? note}) async {
    await Clipboard.setData(ClipboardData(text: await buildReport(draft, note: note)));
  }

  // ───────────────────────── pure helpers (unit tested) ─────────────────────────

  static String composeReport({
    required String environment,
    required String kind,
    String? note,
    required String error,
    required String stack,
    required List<String> logs,
  }) {
    String fence(String s) => s.replaceAll('```', "'''");
    String clean(String s) => fence(LogSanitizer.sanitize(s));

    final cleanNote = (note ?? '').trim();
    final b = StringBuffer()
      ..writeln('<!-- Generated by Kerlyss. Emails, IP addresses, user names and URL parameters were removed from the text below. -->')
      ..writeln('**Environment:** ${clean(environment)}')
      ..writeln('**Kind:** $kind')
      ..writeln()
      ..writeln('### What happened')
      ..writeln(cleanNote.isEmpty ? '_(not described)_' : clean(cleanNote));

    if (error.trim().isNotEmpty) {
      b
        ..writeln()
        ..writeln('### Error')
        ..writeln('```')
        ..writeln(clean(error))
        ..writeln('```');
    }
    if (stack.trim().isNotEmpty) {
      b
        ..writeln()
        ..writeln('### Stack trace (top)')
        ..writeln('```')
        ..writeln(clean(stack))
        ..writeln('```');
    }
    if (logs.isNotEmpty) {
      b
        ..writeln()
        ..writeln('### Recent log (${logs.length} lines)')
        ..writeln('```')
        ..writeln(logs.map(clean).join('\n'))
        ..writeln('```');
    }
    return b.toString();
  }

  /// Builds `issues/new?title=..&body=..`, shrinking the body (logs first, then stack,
  /// then error) until the whole URL fits [maxUrlLength] (GitHub rejects very long URLs).
  static Uri composeIssueUri({
    required String title,
    required String environment,
    required String kind,
    String? note,
    required String error,
    required String stack,
    required List<String> logs,
    int maxUrlLength = 6000,
  }) {
    final safeTitle = LogSanitizer.sanitize(title);

    Uri build(int logCount, int stackLines, int errorChars) {
      final lastLogs = logs.length <= logCount ? logs : logs.sublist(logs.length - logCount);
      final body = composeReport(
        environment: environment,
        kind: kind,
        note: note,
        error: error.length > errorChars ? '${error.substring(0, errorChars)}...' : error,
        stack: stack.split('\n').take(stackLines).join('\n'),
        logs: lastLogs,
      );
      return Uri.parse(issuesNewUrl).replace(queryParameters: {'title': safeTitle, 'body': body});
    }

    const attempts = <List<int>>[
      [40, 12, 600],
      [25, 10, 500],
      [15, 8, 400],
      [8, 6, 300],
      [0, 4, 250],
      [0, 0, 150],
    ];
    for (final a in attempts) {
      final uri = build(a[0], a[1], a[2]);
      if (uri.toString().length <= maxUrlLength) return uri;
    }
    return build(0, 0, 100);
  }

  static String _clip(String s, int max) => s.length > max ? '${s.substring(0, max)}...' : s;
}

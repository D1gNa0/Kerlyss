import 'dart:convert';
import 'dart:io';

import 'app_storage_paths.dart';
import 'logger_service.dart';

/// What the app learned about YouTube, remembered between sessions.
///
/// YouTube refuses "audio only" streams for many users with a 403. The proxy used to find
/// that out on the FIRST song of every session (403, then switch to the muxed stream), so the
/// first song was slow or broken each time. Saving the lesson means the first song already
/// starts the working way.
class YoutubeHints {
  const YoutubeHints({this.audioOnlyBlockedUntil, this.lastGoodClient});

  /// While this time is in the future, "muxed" streams are tried before "audio only".
  final DateTime? audioOnlyBlockedUntil;

  /// The YouTube client ("ANDROID", "IOS", ...) that produced a working stream last time.
  final String? lastGoodClient;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'audioOnlyBlockedUntil': audioOnlyBlockedUntil?.millisecondsSinceEpoch,
        'lastGoodClient': lastGoodClient,
      };

  /// Returns null for broken text. A block time that already passed is dropped.
  static YoutubeHints? tryParse(String text, {DateTime? now}) {
    try {
      final data = jsonDecode(text);
      if (data is! Map<String, dynamic>) return null;
      final until = data['audioOnlyBlockedUntil'];
      final client = data['lastGoodClient'];
      DateTime? blocked;
      if (until is int) {
        final time = DateTime.fromMillisecondsSinceEpoch(until);
        if (time.isAfter(now ?? DateTime.now())) blocked = time;
      }
      return YoutubeHints(
        audioOnlyBlockedUntil: blocked,
        lastGoodClient: client is String && client.isNotEmpty ? client : null,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<File?> _file() async {
    try {
      final dir = await AppStoragePaths.appRootDirectory();
      return File('${dir.path}${Platform.pathSeparator}youtube_hints.json');
    } catch (_) {
      return null;
    }
  }

  /// Never throws.
  static Future<YoutubeHints?> load() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return null;
    try {
      final file = await _file();
      if (file == null || !await file.exists()) return null;
      return tryParse(await file.readAsString());
    } catch (e) {
      Log.w('YoutubeHints: could not load', e);
      return null;
    }
  }

  /// Never throws.
  Future<void> save() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      final file = await _file();
      if (file == null) return;
      await file.writeAsString(jsonEncode(toJson()), flush: true);
    } catch (e) {
      Log.w('YoutubeHints: could not save', e);
    }
  }
}

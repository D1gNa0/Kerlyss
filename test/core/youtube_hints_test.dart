import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kerlyss/core/services/youtube_hints.dart';

void main() {
  group('YoutubeHints', () {
    final now = DateTime(2026, 11, 1, 12);

    test('survives a JSON round trip', () {
      final future = now.add(const Duration(hours: 5));
      final hints = YoutubeHints(audioOnlyBlockedUntil: future, lastGoodClient: 'ANDROID');

      final parsed = YoutubeHints.tryParse(jsonEncode(hints.toJson()), now: now);

      expect(parsed, isNotNull);
      expect(parsed!.audioOnlyBlockedUntil, future);
      expect(parsed.lastGoodClient, 'ANDROID');
    });

    test('a block time that already passed is dropped', () {
      final past = now.subtract(const Duration(minutes: 1));
      final text = jsonEncode(YoutubeHints(audioOnlyBlockedUntil: past, lastGoodClient: 'IOS').toJson());

      final parsed = YoutubeHints.tryParse(text, now: now);

      expect(parsed!.audioOnlyBlockedUntil, isNull);
      expect(parsed.lastGoodClient, 'IOS');
    });

    test('empty values are fine', () {
      final parsed = YoutubeHints.tryParse('{}', now: now);
      expect(parsed, isNotNull);
      expect(parsed!.audioOnlyBlockedUntil, isNull);
      expect(parsed.lastGoodClient, isNull);
    });

    test('bad text gives null and never throws', () {
      expect(YoutubeHints.tryParse('', now: now), isNull);
      expect(YoutubeHints.tryParse('not json', now: now), isNull);
      expect(YoutubeHints.tryParse('[]', now: now), isNull);
    });

    test('wrong types are ignored', () {
      final parsed = YoutubeHints.tryParse('{"audioOnlyBlockedUntil":"soon","lastGoodClient":5}', now: now);
      expect(parsed!.audioOnlyBlockedUntil, isNull);
      expect(parsed.lastGoodClient, isNull);
    });
  });
}

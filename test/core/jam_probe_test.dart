import 'package:flutter_test/flutter_test.dart';
import 'package:kerlyss/core/services/jam_probe.dart';

void main() {
  group('DelayStats', () {
    test('empty has a clear text', () {
      expect(DelayStats().summary, 'no data yet');
    });

    test('shows min, average and max', () {
      final stats = DelayStats()
        ..add(const Duration(milliseconds: 1000))
        ..add(const Duration(milliseconds: 2000))
        ..add(const Duration(milliseconds: 6000));

      expect(stats.count, 3);
      expect(stats.summary, 'n=3   min 1.0s   avg 3.0s   max 6.0s');
    });

    test('keeps only the last 50 values', () {
      final stats = DelayStats();
      for (var i = 0; i < 60; i++) {
        stats.add(Duration(seconds: i));
      }
      expect(stats.count, 50);
      expect(stats.summary, contains('min 10.0s'));
    });
  });
}

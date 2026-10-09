import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerlyss/core/services/toast_service.dart';

void main() {
  testWidgets('toast never blocks taps on widgets underneath it', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Align(
              // Top of the screen = exactly where the toast is drawn.
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton(
                  onPressed: () {
                    taps++;
                    ToastService.show(context, 'Hello toast');
                  },
                  child: const Text('tap me'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('tap me'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Hello toast'), findsOneWidget);

    // Toast is on screen; the button must still receive taps.
    await tester.tap(find.text('tap me'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(taps, 2);

    // Let timers finish so the test ends cleanly.
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Hello toast'), findsNothing);
  });
}

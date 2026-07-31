import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerlyss/presentation/common/vercel_hover_button.dart';

void main() {
  testWidgets('VercelHoverButton renders child and triggers onTap callback', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VercelHoverButton(
            onTap: () => tapped = true,
            child: const Text('Vercel Button'),
          ),
        ),
      ),
    );

    expect(find.text('Vercel Button'), findsOneWidget);
    await tester.tap(find.byType(VercelHoverButton));
    expect(tapped, isTrue);
  });
}

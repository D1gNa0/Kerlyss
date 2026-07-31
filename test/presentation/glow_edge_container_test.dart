import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerlyss/presentation/common/glow_edge_container.dart';

void main() {
  testWidgets('GlowEdgeContainer renders child with glowing stroke border', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GlowEdgeContainer(
            child: Text('Glowing Button'),
          ),
        ),
      ),
    );

    expect(find.byType(GlowEdgeContainer), findsOneWidget);
    expect(find.text('Glowing Button'), findsOneWidget);
  });
}

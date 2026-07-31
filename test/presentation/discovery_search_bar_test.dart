import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerlyss/presentation/common/vercel_hover_button.dart';
import 'package:kerlyss/presentation/screens/discovery_components/discovery_search_bar.dart';
import 'package:kerlyss/presentation/state/discovery_search_provider.dart';
import 'package:kerlyss/l10n/app_localizations.dart';

void main() {
  Widget createWidgetUnderTest({
    required FocusNode focusNode,
    required TextEditingController controller,
    required VoidCallback onSearchTriggered,
  }) {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DiscoverySearchBar(
            focusNode: focusNode,
            controller: controller,
            onSearchTriggered: onSearchTriggered,
          ),
        ),
      ),
    );
  }

  group('DiscoverySearchBar Widget Tests', () {
    late FocusNode focusNode;
    late TextEditingController controller;
    late bool searchTriggered;

    setUp(() {
      focusNode = FocusNode();
      controller = TextEditingController();
      searchTriggered = false;
    });

    tearDown(() {
      focusNode.dispose();
      controller.dispose();
    });

    testWidgets('1. Container height is 60px', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        focusNode: focusNode,
        controller: controller,
        onSearchTriggered: () => searchTriggered = true,
      ));

      final sizedBoxFinder = find.ancestor(
        of: find.byType(TextField),
        matching: find.byType(SizedBox),
      );

      expect(sizedBoxFinder, findsWidgets);
      final sizedBox = tester.widget<SizedBox>(sizedBoxFinder.first);
      expect(sizedBox.height, equals(60.0));
    });

    testWidgets('2. Touch targets of mode toggle chip and clear button meet touch constraints',
        (WidgetTester tester) async {
      controller.text = 'hello';
      await tester.pumpWidget(createWidgetUnderTest(
        focusNode: focusNode,
        controller: controller,
        onSearchTriggered: () => searchTriggered = true,
      ));

      final iconButtons = tester.widgetList<AetherIconButton>(find.byType(AetherIconButton));
      expect(iconButtons.length, greaterThanOrEqualTo(2));

      for (final btn in iconButtons) {
        expect(btn.buttonSize, greaterThanOrEqualTo(40.0));
      }
    });

    testWidgets('3. Clear (X) button visibility and function', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        focusNode: focusNode,
        controller: controller,
        onSearchTriggered: () => searchTriggered = true,
      ));

      // Initially empty text, clear button should not be present
      expect(find.byIcon(Icons.close_rounded), findsNothing);

      // Enter text
      controller.text = 'search term';
      await tester.pump();

      // Clear button should be visible now
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Tap clear button
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(controller.text, isEmpty);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('4. TextInputAction.search and keyboard submission handling', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        focusNode: focusNode,
        controller: controller,
        onSearchTriggered: () => searchTriggered = true,
      ));

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.textInputAction, equals(TextInputAction.search));

      // Focus text field and type text
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'my song');
      await tester.pump();

      // Submit via keyboard
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(milliseconds: 600));

      expect(searchTriggered, isTrue);
      expect(focusNode.hasFocus, isFalse);
    });

    testWidgets('5. Focus node state triggers rebuild with focus border/glow', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        focusNode: focusNode,
        controller: controller,
        onSearchTriggered: () => searchTriggered = true,
      ));

      expect(focusNode.hasFocus, isFalse);

      focusNode.requestFocus();
      await tester.pumpAndSettle();

      expect(focusNode.hasFocus, isTrue);
      final animatedContainer = tester.widget<AnimatedContainer>(
        find.ancestor(of: find.byType(TextField), matching: find.byType(AnimatedContainer)),
      );
      final decoration = animatedContainer.decoration as BoxDecoration;
      expect(decoration.gradient, isNotNull);
      expect(decoration.boxShadow, isNotEmpty);
    });
  });
}

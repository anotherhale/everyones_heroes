import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/features/life_journey/presentation/screens/reflect_screen.dart';

void main() {
  group('ReflectScreen', () {
    Future<void> buildScreen(WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ReflectScreen()));
    }

    Future<void> scrollToBottom(WidgetTester tester) async {
      final scrollView = find.byType(CustomScrollView);

      expect(scrollView, findsOneWidget);

      await tester.drag(scrollView, const Offset(0, -1000));
      await tester.pumpAndSettle();
    }

    testWidgets('renders the reflection experience', (tester) async {
      await buildScreen(tester);

      expect(find.text('Reflect'), findsOneWidget);
      expect(find.text('Take a moment.'), findsOneWidget);
      expect(
        find.text('How are you feeling about your journey?'),
        findsOneWidget,
      );
      expect(find.text('What best describes this moment?'), findsOneWidget);

      expect(find.text('Strong'), findsOneWidget);
      expect(find.text('Growing'), findsOneWidget);
      expect(find.text('Motivated'), findsOneWidget);
      expect(find.text('Peaceful'), findsOneWidget);

      await scrollToBottom(tester);

      expect(find.byKey(const ValueKey('feeling-grateful')), findsOneWidget);
    });

    testWidgets('save reflection is disabled until a feeling is selected', (
      tester,
    ) async {
      await buildScreen(tester);
      await scrollToBottom(tester);

      final saveButton = find.byKey(const ValueKey('save-reflection'));

      expect(saveButton, findsOneWidget);

      final button = tester.widget<FilledButton>(saveButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('selecting a feeling enables save and shows confirmation', (
      tester,
    ) async {
      await buildScreen(tester);
      await scrollToBottom(tester);

      final growing = find.byKey(const ValueKey('feeling-growing'));

      expect(growing, findsOneWidget);

      await tester.tap(growing);
      await tester.pump();

      final saveButton = find.byKey(const ValueKey('save-reflection'));

      expect(saveButton, findsOneWidget);

      final button = tester.widget<FilledButton>(saveButton);
      expect(button.onPressed, isNotNull);

      await tester.tap(saveButton);
      await tester.pump();

      expect(find.text('Reflection saved: Growing'), findsOneWidget);
    });

    testWidgets('selected feeling is visually marked', (tester) async {
      await buildScreen(tester);
      await scrollToBottom(tester);

      final grateful = find.byKey(const ValueKey('feeling-grateful'));

      expect(grateful, findsOneWidget);

      await tester.tap(grateful);
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}

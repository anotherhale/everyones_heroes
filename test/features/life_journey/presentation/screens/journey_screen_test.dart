import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/features/life_journey/presentation/screens/journey_screen.dart';

void main() {
  group('JourneyScreen', () {
    testWidgets('renders the journey introduction', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: JourneyScreen()));

      expect(find.text('Your Journey'), findsOneWidget);
      expect(
        find.text('Your story is built one step at a time.'),
        findsOneWidget,
      );
    });

    testWidgets('renders the journey path', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: JourneyScreen()));

      expect(find.text('Beginning'), findsOneWidget);
      expect(find.text('Finding Your Strength'), findsWidgets);
      expect(find.text('You Are Here'), findsOneWidget);
      expect(find.text("What's Next?"), findsOneWidget);
      expect(find.text('The Road Ahead'), findsOneWidget);
    });

    testWidgets('renders the current chapter and next step', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: JourneyScreen()));

      await tester.scrollUntilVisible(
        find.text('CURRENT CHAPTER'),
        300,
        scrollable: find.byType(Scrollable),
      );

      expect(find.text('CURRENT CHAPTER'), findsOneWidget);
      expect(find.text('4 quests completed'), findsOneWidget);
      expect(find.text('3 reflections'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('NEXT STEP'),
        300,
        scrollable: find.byType(Scrollable),
      );

      expect(find.text('NEXT STEP'), findsOneWidget);
      expect(find.text("Continue today's journey"), findsOneWidget);
      expect(find.text('Take the next meaningful step.'), findsOneWidget);
    });
  });
}

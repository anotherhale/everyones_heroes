import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/features/life_journey/presentation/screens/home_screen.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('renders the primary home experience', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      expect(find.text('Good morning.'), findsOneWidget);
      expect(
        find.text(
          "You don't have to change everything today.\n"
          'Just take the next step.',
        ),
        findsOneWidget,
      );
      expect(find.text("TODAY'S EXPERIENCE"), findsOneWidget);
      expect(find.text('Take the next step.'), findsOneWidget);
      expect(find.text('Begin Experience'), findsOneWidget);
    });

    testWidgets('renders journey, discovery, and reflection entry points', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Journey is initially near the visible portion of the screen.
      expect(find.text('YOUR JOURNEY'), findsOneWidget);
      expect(find.text('Continue your journey'), findsOneWidget);

      // Scroll to the Discovery section.
      await tester.scrollUntilVisible(
        find.text('DISCOVER'),
        300,
        scrollable: find.byType(Scrollable),
      );

      expect(find.text('DISCOVER'), findsOneWidget);
      expect(find.text('Learn something about yourself'), findsOneWidget);

      // Scroll further to the Reflection section.
      await tester.scrollUntilVisible(
        find.text('REFLECT'),
        300,
        scrollable: find.byType(Scrollable),
      );

      expect(find.text('REFLECT'), findsOneWidget);
      expect(find.text('Reflect on an experience'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/features/life_journey/presentation/screens/discover_screen.dart';

void main() {
  group('DiscoverScreen', () {
    testWidgets('renders the discovery introduction', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: DiscoverScreen()));

      expect(find.text('Discover'), findsOneWidget);
      expect(find.text('What would you like to discover?'), findsOneWidget);
    });

    testWidgets('renders the three discovery paths', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: DiscoverScreen()));

      expect(find.text('What gives me energy?'), findsOneWidget);
      expect(find.text('Notice what brings you alive.'), findsOneWidget);

      expect(find.text('What am I good at?'), findsOneWidget);
      expect(
        find.text('Recognize strengths you may overlook.'),
        findsOneWidget,
      );

      expect(find.text('What matters to me?'), findsOneWidget);
      expect(
        find.text('Explore the things that give your life meaning.'),
        findsOneWidget,
      );
    });

    testWidgets('renders unexpected discovery', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: DiscoverScreen()));

      await tester.scrollUntilVisible(
        find.text('Something unexpected'),
        300,
        scrollable: find.byType(Scrollable),
      );

      expect(find.text('Something unexpected'), findsOneWidget);
      expect(
        find.text('You may be more resilient than you realize.'),
        findsOneWidget,
      );
      expect(find.text('Explore'), findsOneWidget);
    });
  });
}

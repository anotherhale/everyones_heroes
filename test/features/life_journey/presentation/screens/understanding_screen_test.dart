import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:everyonesheroes/features/life_journey/presentation/screens/understanding_screen.dart';

void main() {
  Widget buildSubject() {
    return const MaterialApp(home: UnderstandingScreen());
  }

  testWidgets('UnderstandingScreen renders the understanding experience', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('Understanding'), findsOneWidget);
    expect(
      find.text("We're starting to notice a few things about you."),
      findsOneWidget,
    );
    expect(find.text('You keep showing up.'), findsOneWidget);
    expect(find.text('Helping others matters to you.'), findsOneWidget);
  });

  testWidgets('UnderstandingScreen communicates that understanding grows', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    final growthMessage = find.text('This understanding grows over time.');

    await tester.scrollUntilVisible(
      growthMessage,
      500,
      scrollable: find.byType(Scrollable),
    );

    expect(growthMessage, findsOneWidget);
    expect(
      find.textContaining('Every experience and reflection'),
      findsOneWidget,
    );
  });

  testWidgets(
    'UnderstandingScreen does not expose internal behavior concepts',
    (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.textContaining('BehaviorPattern'), findsNothing);
      expect(find.textContaining('strength'), findsNothing);
      expect(find.textContaining('observation count'), findsNothing);
      expect(find.textContaining('evidence'), findsNothing);
    },
  );
}

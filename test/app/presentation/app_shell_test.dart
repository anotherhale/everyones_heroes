import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/app/presentation/app_shell.dart';

void main() {
  Widget buildSubject() {
    return const MaterialApp(home: AppShell());
  }

  testWidgets('AppShell starts on Home', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Good morning.'), findsOneWidget);

    expect(find.byKey(const Key('nav-home')), findsOneWidget);
    expect(find.byKey(const Key('nav-journey')), findsOneWidget);
    expect(find.byKey(const Key('nav-discover')), findsOneWidget);
    expect(find.byKey(const Key('nav-reflect')), findsOneWidget);
  });

  testWidgets('AppShell navigates to Journey', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-journey')));
    await tester.pumpAndSettle();

    expect(find.text('Your Journey'), findsOneWidget);
  });

  testWidgets('AppShell navigates to Discover', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-discover')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen-title-discover')), findsOneWidget);
  });

  testWidgets('AppShell navigates to Reflect', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-reflect')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-reflect')));
    await tester.pumpAndSettle();

    final scrollView = find.byType(CustomScrollView);
    expect(scrollView, findsOneWidget);

    await tester.drag(scrollView, const Offset(0, -1000));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('save-reflection')), findsOneWidget);
  });
}

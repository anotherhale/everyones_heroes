import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/influence_reference_ids.dart';
import 'package:everyonesheroes/features/discovery/application/providers/repositories/discovery_profile_repository_provider.dart';
import 'package:everyonesheroes/features/discovery/application/providers/repositories/influence_repository_provider.dart';
import 'package:everyonesheroes/features/discovery/application/providers/use_cases/discovery_use_case_providers.dart';
import 'package:everyonesheroes/features/discovery/domain/entities/influence.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_discovery_profile_repository.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_influence_repository.dart';
import 'package:everyonesheroes/features/life_journey/presentation/screens/discover_screen.dart';

void main() {
  ProviderScope buildSubject({
    bool emptyCatalog = false,
  }) {
    return ProviderScope(
      overrides: [
        discoveryProfileRepositoryProvider.overrideWithValue(
          InMemoryDiscoveryProfileRepository(),
        ),
        influenceRepositoryProvider.overrideWithValue(
          InMemoryInfluenceRepository.withReferenceCatalog(),
        ),
        if (emptyCatalog)
          curatedInfluencesProvider.overrideWith(
            (ref) async => const <Influence>[],
          ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: DiscoverScreen()),
      ),
    );
  }

  group('DiscoverScreen D.3 Influence selection', () {
    testWidgets('renders inspiration prompt and curated Influences', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Discover'), findsOneWidget);
      expect(find.text('What inspires you?'), findsOneWidget);
      expect(find.text('Rocky Balboa'), findsOneWidget);
      expect(find.text('Save inspirations'), findsOneWidget);
    });

    testWidgets('selecting an Influence shows selected state', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final rockyKey = Key(
        'influence-tile-${InfluenceReferenceIds.rockyBalboa.value}',
      );
      await tester.scrollUntilVisible(
        find.byKey(rockyKey),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(rockyKey));
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });

    testWidgets('save invokes application layer and shows selected chip', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final rockyKey = Key(
        'influence-tile-${InfluenceReferenceIds.rockyBalboa.value}',
      );
      await tester.ensureVisible(find.byKey(rockyKey));
      await tester.tap(find.byKey(rockyKey));
      await tester.pump();

      final saveButton = find.byKey(const Key('save-influences-button'));
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          Key(
            'selected-influence-chip-${InfluenceReferenceIds.rockyBalboa.value}',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('Saved'), findsWidgets);
      expect(find.text('Your inspirations were saved.'), findsOneWidget);
    });

    testWidgets('empty catalog shows graceful empty state', (tester) async {
      await tester.pumpWidget(buildSubject(emptyCatalog: true));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('influence-catalog-empty')),
        findsOneWidget,
      );
      expect(
        find.text('No curated inspirations are available right now.'),
        findsOneWidget,
      );
    });
  });
}

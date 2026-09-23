import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_reference_ids.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/features/discovery/application/services/catalog_aligned_narrative_theme_resolver.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';
import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/journal_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CatalogAlignedNarrativeThemeResolver', () {
    const resolver = CatalogAlignedNarrativeThemeResolver();

    test('emits only catalog-valid IDs (never self-discovery)', () async {
      final reflection = Reflection.create(
        id: ReflectionId.generate(),
        journeyId: JourneyId.generate(),
      );
      reflection.addResponse(const JournalResponse(response: 'Test'));

      final themes = await resolver.resolveThemes(reflection);

      expect(themes, [NarrativeThemeReferenceIds.discovery]);
      for (final theme in themes) {
        expect(NarrativeThemeReferenceIds.all.contains(theme), isTrue);
        expect(theme.value, isNot('self-discovery'));
      }
    });

    test('resolution is deterministic', () async {
      final reflection = Reflection.create(
        id: ReflectionId.generate(),
        journeyId: JourneyId.generate(),
      );

      final a = await resolver.resolveThemes(reflection);
      final b = await resolver.resolveThemes(reflection);
      expect(a, b);
    });
  });
}

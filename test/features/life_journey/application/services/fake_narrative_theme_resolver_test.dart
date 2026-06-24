import '../../../../fakes/life_journey/fake_narrative_theme_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';

import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';

import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/journal_response.dart';

void main() {
  group('FakeNarrativeThemeResolver', () {
    const service = FakeNarrativeThemeResolver();

    test('returns empty when no responses exist', () async {
      final reflection = Reflection.create(
        id: ReflectionId.generate(),
        journeyId: JourneyId.generate(),
      );

      final themes = await service.resolveThemes(reflection);

      expect(themes, isEmpty);
    });

    test('returns themes when responses exist', () async {
      final reflection = Reflection.create(
        id: ReflectionId.generate(),
        journeyId: JourneyId.generate(),
      );

      reflection.addResponse(const JournalResponse(response: 'Test'));

      final themes = await service.resolveThemes(reflection);

      expect(themes, isNotEmpty);
    });
  });
}

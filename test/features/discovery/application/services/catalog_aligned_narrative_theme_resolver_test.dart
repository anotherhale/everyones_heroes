import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_reference_ids.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/features/discovery/application/services/catalog_aligned_narrative_theme_resolver.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';
import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/choice_response.dart';
import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/journal_response.dart';
import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/prompt_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CatalogAlignedNarrativeThemeResolver', () {
    const resolver = CatalogAlignedNarrativeThemeResolver();

    test('unrecognized content falls back to catalog discovery', () async {
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

    test('empty responses fall back to catalog discovery', () async {
      final reflection = Reflection.create(
        id: ReflectionId.generate(),
        journeyId: JourneyId.generate(),
      );

      final themes = await resolver.resolveThemes(reflection);

      expect(themes, [NarrativeThemeReferenceIds.discovery]);
    });

    test('matches catalog theme name courage from journal text', () async {
      final reflection = Reflection.create(
        id: ReflectionId.generate(),
        journeyId: JourneyId.generate(),
      );
      reflection.addResponse(
        const JournalResponse(
          response: 'Today I found courage when I spoke up.',
        ),
      );

      final themes = await resolver.resolveThemes(reflection);

      expect(themes, [NarrativeThemeReferenceIds.courage]);
    });

    test('matches catalog theme name service from journal text', () async {
      final reflection = Reflection.create(
        id: ReflectionId.generate(),
        journeyId: JourneyId.generate(),
      );
      reflection.addResponse(
        const JournalResponse(
          response: 'I want to grow through service to others.',
        ),
      );

      final themes = await resolver.resolveThemes(reflection);

      expect(themes, [NarrativeThemeReferenceIds.service]);
    });

    test('matches multiple catalog themes in catalog order', () async {
      final reflection = Reflection.create(
        id: ReflectionId.generate(),
        journeyId: JourneyId.generate(),
      );
      reflection.addResponse(
        const JournalResponse(
          response: 'I needed courage and perseverance to keep going.',
        ),
      );

      final themes = await resolver.resolveThemes(reflection);

      expect(themes, [
        NarrativeThemeReferenceIds.courage,
        NarrativeThemeReferenceIds.perseverance,
      ]);
    });

    test('does not match substrings inside unrelated words', () async {
      final reflection = Reflection.create(
        id: ReflectionId.generate(),
        journeyId: JourneyId.generate(),
      );
      // "courage" must not match inside "discourage"
      reflection.addResponse(
        const JournalResponse(response: 'I will not discourage myself.'),
      );

      final themes = await resolver.resolveThemes(reflection);

      expect(themes, [NarrativeThemeReferenceIds.discovery]);
      expect(themes, isNot(contains(NarrativeThemeReferenceIds.courage)));
    });

    test('matches prompt and choice response text', () async {
      final reflection = Reflection.create(
        id: ReflectionId.generate(),
        journeyId: JourneyId.generate(),
      );
      reflection.addResponse(
        PromptResponse(
          prompt: 'What guided you?',
          response: 'Leadership under pressure.',
        ),
      );
      reflection.addResponse(
        ChoiceResponse(
          question: 'Which theme?',
          selectedOption: 'Family',
          options: const ['Family', 'Other'],
        ),
      );

      final themes = await resolver.resolveThemes(reflection);

      expect(themes, [
        NarrativeThemeReferenceIds.leadership,
        NarrativeThemeReferenceIds.family,
      ]);
    });

    test('resolution is deterministic', () async {
      final reflection = Reflection.create(
        id: ReflectionId.generate(),
        journeyId: JourneyId.generate(),
      );
      reflection.addResponse(
        const JournalResponse(response: 'Service and purpose matter.'),
      );

      final a = await resolver.resolveThemes(reflection);
      final b = await resolver.resolveThemes(reflection);
      expect(a, b);
      expect(a, [
        NarrativeThemeReferenceIds.service,
        NarrativeThemeReferenceIds.purpose,
      ]);
    });

    test('emits only catalog-valid IDs', () async {
      final reflection = Reflection.create(
        id: ReflectionId.generate(),
        journeyId: JourneyId.generate(),
      );
      reflection.addResponse(
        const JournalResponse(
          response: 'Love and sacrifice shaped my transformation.',
        ),
      );

      final themes = await resolver.resolveThemes(reflection);

      for (final theme in themes) {
        expect(NarrativeThemeReferenceIds.all.contains(theme), isTrue);
      }
      expect(themes, [
        NarrativeThemeReferenceIds.transformation,
        NarrativeThemeReferenceIds.sacrifice,
        NarrativeThemeReferenceIds.love,
      ]);
    });
  });
}

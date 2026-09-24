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

    Reflection journal(String text) {
      final reflection = Reflection.create(
        id: ReflectionId.generate(),
        journeyId: JourneyId.generate(),
      );
      reflection.addResponse(JournalResponse(response: text));
      return reflection;
    }

    test('unrecognized content falls back to catalog discovery', () async {
      final themes = await resolver.resolveThemes(journal('Test'));

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
      final themes = await resolver.resolveThemes(
        journal('Today I found courage when I spoke up.'),
      );

      expect(themes, [NarrativeThemeReferenceIds.courage]);
    });

    test('matches catalog theme name service from journal text', () async {
      final themes = await resolver.resolveThemes(
        journal('I want to grow through service to others.'),
      );

      expect(themes, [NarrativeThemeReferenceIds.service]);
    });

    test(
      'matches catalog description phrase without theme name',
      () async {
        // Existing catalog description for Service:
        // "Helping others through lived experience."
        final themes = await resolver.resolveThemes(
          journal(
            'Lately I keep returning to helping others through lived '
            'experience as what matters most.',
          ),
        );

        expect(themes, [NarrativeThemeReferenceIds.service]);
        expect(themes, isNot(contains(NarrativeThemeReferenceIds.discovery)));
      },
    );

    test(
      'matches catalog alias phrase without theme name or full description',
      () async {
        // Leadership alias (from description language):
        // "taking responsibility for others"
        // Full description is "Guiding or taking responsibility for others."
        final themes = await resolver.resolveThemes(
          journal(
            'This week I have been taking responsibility for others '
            'in ways I used to avoid.',
          ),
        );

        expect(themes, [NarrativeThemeReferenceIds.leadership]);
      },
    );

    test('description matching is case-insensitive', () async {
      final themes = await resolver.resolveThemes(
        journal('ACTING DESPITE FEAR showed up for me today.'),
      );

      expect(themes, [NarrativeThemeReferenceIds.courage]);
    });

    test(
      'punctuation and whitespace normalization supports description match',
      () async {
        final themes = await resolver.resolveThemes(
          journal(
            'I am learning about:  helping others through lived '
            'experience!!!',
          ),
        );

        expect(themes, [NarrativeThemeReferenceIds.service]);
      },
    );

    test('matches multiple catalog themes in catalog order', () async {
      final themes = await resolver.resolveThemes(
        journal('I needed courage and perseverance to keep going.'),
      );

      expect(themes, [
        NarrativeThemeReferenceIds.courage,
        NarrativeThemeReferenceIds.perseverance,
      ]);
    });

    test(
      'multiple description/alias matches resolve in catalog order',
      () async {
        final themes = await resolver.resolveThemes(
          journal(
            'I am acting despite fear while taking responsibility '
            'for others.',
          ),
        );

        expect(themes, [
          NarrativeThemeReferenceIds.courage,
          NarrativeThemeReferenceIds.leadership,
        ]);
      },
    );

    test('does not match substrings inside unrelated words', () async {
      // "courage" must not match inside "discourage"
      final themes = await resolver.resolveThemes(
        journal('I will not discourage myself.'),
      );

      expect(themes, [NarrativeThemeReferenceIds.discovery]);
      expect(themes, isNot(contains(NarrativeThemeReferenceIds.courage)));
    });

    test(
      'does not match partial-word false positives for short names',
      () async {
        final themes = await resolver.resolveThemes(
          journal('The car was serviced yesterday.'),
        );

        expect(themes, [NarrativeThemeReferenceIds.discovery]);
        expect(themes, isNot(contains(NarrativeThemeReferenceIds.service)));
      },
    );

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

    test('resolution is deterministic for identical inputs', () async {
      final reflection = journal('Service and purpose matter.');

      final a = await resolver.resolveThemes(reflection);
      final b = await resolver.resolveThemes(reflection);
      expect(a, b);
      expect(a, [
        NarrativeThemeReferenceIds.service,
        NarrativeThemeReferenceIds.purpose,
      ]);
    });

    test(
      'repeated identical description input produces identical output',
      () async {
        const text =
            'I keep thinking about helping others through lived experience.';
        final a = await resolver.resolveThemes(journal(text));
        final b = await resolver.resolveThemes(journal(text));
        expect(a, b);
        expect(a, [NarrativeThemeReferenceIds.service]);
      },
    );

    test('emits only catalog-valid IDs', () async {
      final themes = await resolver.resolveThemes(
        journal('Love and sacrifice shaped my transformation.'),
      );

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

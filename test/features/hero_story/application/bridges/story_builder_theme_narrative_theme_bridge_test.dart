import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_reference_ids.dart';
import 'package:everyonesheroes/features/hero_story/application/bridges/story_builder_theme_narrative_theme_bridge.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const bridge = StoryBuilderThemeNarrativeThemeBridge();

  group('StoryBuilderThemeNarrativeThemeBridge', () {
    test('maps every StoryBuilderTheme to Discovery reference IDs', () {
      final expected = <StoryBuilderTheme, NarrativeThemeId>{
        StoryBuilderTheme.overcomingAdversity:
            NarrativeThemeReferenceIds.overcomingAdversity,
        StoryBuilderTheme.courage: NarrativeThemeReferenceIds.courage,
        StoryBuilderTheme.service: NarrativeThemeReferenceIds.service,
        StoryBuilderTheme.leadership: NarrativeThemeReferenceIds.leadership,
        StoryBuilderTheme.loss: NarrativeThemeReferenceIds.loss,
        StoryBuilderTheme.failure: NarrativeThemeReferenceIds.failure,
        StoryBuilderTheme.transformation:
            NarrativeThemeReferenceIds.transformation,
        StoryBuilderTheme.perseverance:
            NarrativeThemeReferenceIds.perseverance,
        StoryBuilderTheme.secondChances:
            NarrativeThemeReferenceIds.secondChances,
        StoryBuilderTheme.sacrifice: NarrativeThemeReferenceIds.sacrifice,
        StoryBuilderTheme.family: NarrativeThemeReferenceIds.family,
        StoryBuilderTheme.discovery: NarrativeThemeReferenceIds.discovery,
        StoryBuilderTheme.purpose: NarrativeThemeReferenceIds.purpose,
        StoryBuilderTheme.love: NarrativeThemeReferenceIds.love,
      };

      expect(StoryBuilderTheme.values.length, expected.length);

      for (final theme in StoryBuilderTheme.values) {
        expect(
          bridge.mapTheme(theme),
          expected[theme],
          reason: 'Mapping missing or wrong for $theme',
        );
      }
    });

    test('uses Discovery-owned opaque IDs, not display labels', () {
      expect(bridge.mapTheme(StoryBuilderTheme.courage)!.value, 'courage');
      expect(
        bridge.mapTheme(StoryBuilderTheme.overcomingAdversity)!.value,
        'overcoming-adversity',
      );
      expect(
        bridge.mapTheme(StoryBuilderTheme.secondChances)!.value,
        'second-chances',
      );
      expect(bridge.mapTheme(StoryBuilderTheme.courage)!.value, isNot('Courage'));
      expect(
        bridge.mapTheme(StoryBuilderTheme.perseverance)!.value,
        isNot('Perseverance'),
      );
    });

    test('same Builder theme always resolves to the same NarrativeThemeId', () {
      for (final theme in StoryBuilderTheme.values) {
        final first = bridge.mapTheme(theme);
        final second = bridge.mapTheme(theme);
        expect(first, isNotNull);
        expect(identical(first, second) || first == second, isTrue);
        expect(first, second);
        expect(first!.value, second!.value);
      }
    });

    test('mapThemes preserves order and deduplicates', () {
      final ids = bridge.mapThemes([
        StoryBuilderTheme.courage,
        StoryBuilderTheme.service,
        StoryBuilderTheme.courage,
        StoryBuilderTheme.leadership,
      ]);

      expect(ids, [
        NarrativeThemeReferenceIds.courage,
        NarrativeThemeReferenceIds.service,
        NarrativeThemeReferenceIds.leadership,
      ]);
    });

    test('mapThemes returns empty for empty input', () {
      expect(bridge.mapThemes(const []), isEmpty);
    });

    test('canonical IDs match NarrativeThemeReferenceIds catalog', () {
      final mapped = bridge.mapThemes(StoryBuilderTheme.values).toSet();
      final catalog = NarrativeThemeReferenceIds.all.toSet();
      expect(mapped, catalog);
    });
  });
}

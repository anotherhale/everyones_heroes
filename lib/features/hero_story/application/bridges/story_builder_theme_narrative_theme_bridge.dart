import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/features/discovery/domain/catalog/narrative_theme_reference_ids.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_theme.dart';

/// Application-boundary bridge: Story Builder theme intent → Discovery IDs.
///
/// ```text
/// StoryBuilderTheme  →  NarrativeThemeId  →  Discovery NarrativeTheme
/// ```
///
/// Rules:
/// * Does not create [NarrativeTheme] entities in Hero & Story.
/// * Does not update Discovery profiles or preferences.
/// * Does not create BehavioralEvidence or personalization signals.
/// * Uses Discovery-owned [NarrativeThemeReferenceIds] as canonical identity.
/// * Unmapped themes are omitted (never invents fake IDs).
final class StoryBuilderThemeNarrativeThemeBridge {
  const StoryBuilderThemeNarrativeThemeBridge();

  /// Maps Builder themes to Discovery [NarrativeThemeId]s.
  ///
  /// Deduplicates while preserving first-seen order. Omits any theme without a
  /// Discovery mapping (none of the current enum values are unmapped).
  List<NarrativeThemeId> mapThemes(Iterable<StoryBuilderTheme> themes) {
    final seen = <NarrativeThemeId>{};
    final result = <NarrativeThemeId>[];
    for (final theme in themes) {
      final id = mapTheme(theme);
      if (id == null) continue;
      if (seen.add(id)) {
        result.add(id);
      }
    }
    return List.unmodifiable(result);
  }

  /// Maps a single Builder theme, or `null` when no Discovery mapping exists.
  NarrativeThemeId? mapTheme(StoryBuilderTheme theme) {
    return switch (theme) {
      StoryBuilderTheme.overcomingAdversity =>
        NarrativeThemeReferenceIds.overcomingAdversity,
      StoryBuilderTheme.courage => NarrativeThemeReferenceIds.courage,
      StoryBuilderTheme.service => NarrativeThemeReferenceIds.service,
      StoryBuilderTheme.leadership => NarrativeThemeReferenceIds.leadership,
      StoryBuilderTheme.loss => NarrativeThemeReferenceIds.loss,
      StoryBuilderTheme.failure => NarrativeThemeReferenceIds.failure,
      StoryBuilderTheme.transformation =>
        NarrativeThemeReferenceIds.transformation,
      StoryBuilderTheme.perseverance =>
        NarrativeThemeReferenceIds.perseverance,
      StoryBuilderTheme.secondChances =>
        NarrativeThemeReferenceIds.secondChances,
      StoryBuilderTheme.sacrifice => NarrativeThemeReferenceIds.sacrifice,
      StoryBuilderTheme.family => NarrativeThemeReferenceIds.family,
      StoryBuilderTheme.discovery => NarrativeThemeReferenceIds.discovery,
      StoryBuilderTheme.purpose => NarrativeThemeReferenceIds.purpose,
      StoryBuilderTheme.love => NarrativeThemeReferenceIds.love,
    };
  }
}

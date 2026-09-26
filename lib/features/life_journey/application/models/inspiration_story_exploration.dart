import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';

/// Application result for inspiration-grounded Story exploration (D.7).
///
/// Sourced exclusively from DiscoveryProfile Narrative Themes via
/// Influence → NarrativeTheme resolution — never from Reflection signals.
final class InspirationStoryExploration {
  const InspirationStoryExploration({
    required this.hasInspirations,
    required this.inspirationThemeIds,
    required this.stories,
  });

  /// Empty exploration when the person has no current Inspirations.
  factory InspirationStoryExploration.withoutInspirations() {
    return const InspirationStoryExploration(
      hasInspirations: false,
      inspirationThemeIds: [],
      stories: [],
    );
  }

  /// Whether the current DiscoveryProfile has at least one Influence.
  final bool hasInspirations;

  /// Resolved NarrativeThemeIds from the person's current Inspirations.
  final List<NarrativeThemeId> inspirationThemeIds;

  /// Eligible Stories whose themes overlap [inspirationThemeIds].
  final List<InspirationGroundedStory> stories;

  bool get isEmpty => stories.isEmpty;
}

/// A discoverable Story surfaced because its themes overlap current
/// Inspiration themes.
final class InspirationGroundedStory {
  InspirationGroundedStory({
    required this.storyId,
    required this.heroId,
    required this.title,
    required List<NarrativeThemeId> matchedThemeIds,
    required List<String> matchedThemeNames,
    this.heroDisplayName,
  })  : matchedThemeIds = List.unmodifiable(matchedThemeIds),
        matchedThemeNames = List.unmodifiable(matchedThemeNames);

  final StoryId storyId;
  final HeroId heroId;
  final String title;
  final String? heroDisplayName;

  /// Theme IDs present on both the Story and the person's Inspirations.
  final List<NarrativeThemeId> matchedThemeIds;

  /// Display names for [matchedThemeIds] (Discovery-owned labels).
  final List<String> matchedThemeNames;

  /// Provenance copy grounded in Inspiration themes — never Reflection.
  String get relevanceLabel {
    if (matchedThemeNames.isEmpty) {
      return 'Connected to your inspirations';
    }
    if (matchedThemeNames.length == 1) {
      return 'Connected through ${matchedThemeNames.first}';
    }
    final leading = matchedThemeNames.take(matchedThemeNames.length - 1).join(
          ', ',
        );
    final last = matchedThemeNames.last;
    return 'Connected through $leading and $last';
  }
}

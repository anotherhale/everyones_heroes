import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';

/// Application DTO for a ranked discoverable Story candidate (HS.8).
///
/// Produced only via Discover*-backed adapters — never raw repositories.
final class DiscoverableStoryCandidate {
  DiscoverableStoryCandidate({
    required this.storyId,
    required this.heroId,
    required this.title,
    required List<NarrativeThemeId> matchedThemeIds,
    required this.themeOverlapCount,
    required this.patternBoost,
    required this.updatedAt,
  }) : matchedThemeIds = List.unmodifiable(matchedThemeIds);

  final StoryId storyId;
  final HeroId heroId;
  final String title;
  final List<NarrativeThemeId> matchedThemeIds;
  final int themeOverlapCount;

  /// Deterministic secondary boost from behavior pattern strength (0.0–1.0).
  final double patternBoost;
  final DateTime updatedAt;

  /// Primary ranking key: theme overlap dominates; patterns strengthen ties.
  double get relevanceScore => themeOverlapCount + patternBoost;
}

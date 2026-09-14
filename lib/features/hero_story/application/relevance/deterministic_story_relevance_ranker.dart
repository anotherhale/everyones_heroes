import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/story_discovery_summary.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_discovery_signals.dart';
import 'package:everyonesheroes/features/life_journey/application/models/discoverable_story_candidate.dart';

/// Deterministic, explainable Story relevance ranking over Discover* results.
///
/// Scoring:
/// - Primary: narrative theme overlap count
/// - Secondary: max behavior-pattern strength when overlap > 0 (0.0–1.0)
/// - Tie-break: updatedAt desc, then storyId asc (HS.6 ordering)
///
/// Patterns strengthen relevance; they do not create relevance without themes.
final class DeterministicStoryRelevanceRanker {
  const DeterministicStoryRelevanceRanker();

  List<DiscoverableStoryCandidate> rank({
    required List<StoryDiscoverySummary> summaries,
    required AdaptiveDiscoverySignals signals,
  }) {
    final signalThemeValues = {
      for (final id in signals.narrativeThemeIds) id.value,
    };

    final patternBoost = _patternBoost(signals);

    final candidates = <DiscoverableStoryCandidate>[];

    for (final summary in summaries) {
      final matched = <NarrativeThemeId>[];
      for (final themeId in summary.narrativeThemeIds) {
        if (signalThemeValues.contains(themeId.value)) {
          matched.add(themeId);
        }
      }

      if (matched.isEmpty) {
        continue;
      }

      candidates.add(
        DiscoverableStoryCandidate(
          storyId: summary.storyId,
          heroId: summary.heroId,
          title: summary.title,
          matchedThemeIds: matched,
          themeOverlapCount: matched.length,
          patternBoost: patternBoost,
          updatedAt: summary.updatedAt,
        ),
      );
    }

    candidates.sort(_compare);

    return List.unmodifiable(candidates);
  }

  static double _patternBoost(AdaptiveDiscoverySignals signals) {
    if (!signals.hasPatterns) {
      return 0.0;
    }

    var maxStrength = 0.0;
    for (final pattern in signals.behaviorPatterns) {
      if (pattern.strength.value > maxStrength) {
        maxStrength = pattern.strength.value;
      }
    }
    return maxStrength;
  }

  static int _compare(
    DiscoverableStoryCandidate a,
    DiscoverableStoryCandidate b,
  ) {
    final overlap = b.themeOverlapCount.compareTo(a.themeOverlapCount);
    if (overlap != 0) {
      return overlap;
    }

    final boost = b.patternBoost.compareTo(a.patternBoost);
    if (boost != 0) {
      return boost;
    }

    final updated = b.updatedAt.compareTo(a.updatedAt);
    if (updated != 0) {
      return updated;
    }

    return a.storyId.value.compareTo(b.storyId.value);
  }
}

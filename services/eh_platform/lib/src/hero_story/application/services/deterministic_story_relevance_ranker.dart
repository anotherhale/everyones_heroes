import 'package:eh_platform/src/experience/application/models/adaptive_discovery_signals.dart';
import 'package:eh_platform/src/experience/application/models/discoverable_story_candidate.dart';
import 'package:eh_platform/src/hero_story/domain/models/story_candidate_record.dart';

/// Deterministic, explainable Story relevance ranking (HS.8 / J.2 Slice 3).
///
/// Ported from Flutter `DeterministicStoryRelevanceRanker`.
///
/// Scoring:
/// - Primary: narrative theme overlap count
/// - Secondary: most recently expressed matched theme (Reflection submission)
/// - Tertiary: max behavior-pattern strength when overlap > 0 (0.0–1.0)
/// - Tie-break: updatedAt desc, then storyId asc
///
/// Patterns strengthen relevance; they do not create relevance without themes.
/// Theme recency prefers Stories aligned with recent understanding over
/// historical union + Story publish-time ties.
/// No ML, embeddings, popularity, or engagement metrics.
final class DeterministicStoryRelevanceRanker {
  const DeterministicStoryRelevanceRanker();

  List<DiscoverableStoryCandidate> rank({
    required List<StoryCandidateRecord> records,
    required AdaptiveDiscoverySignals signals,
  }) {
    final signalThemeValues = signals.narrativeThemeIds.toSet();
    final patternBoost = _patternBoost(signals);
    final themeLastExpressedAt = signals.themeLastExpressedAt;

    final candidates = <DiscoverableStoryCandidate>[];

    for (final record in records) {
      final matched = <String>[];
      for (final themeId in record.themeIds) {
        if (signalThemeValues.contains(themeId)) {
          matched.add(themeId);
        }
      }

      if (matched.isEmpty) {
        continue;
      }

      matched.sort();

      candidates.add(
        DiscoverableStoryCandidate(
          storyId: record.storyId,
          heroId: record.heroId,
          title: record.title,
          matchedThemeIds: matched,
          themeOverlapCount: matched.length,
          patternBoost: patternBoost,
          updatedAt: record.updatedAt,
        ),
      );
    }

    candidates.sort(
      (a, b) => _compare(a, b, themeLastExpressedAt),
    );
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

  static DateTime _maxMatchedThemeExpressedAt(
    List<String> matchedThemeIds,
    Map<String, DateTime> themeLastExpressedAt,
  ) {
    DateTime? best;
    for (final themeId in matchedThemeIds) {
      final at = themeLastExpressedAt[themeId];
      if (at == null) {
        continue;
      }
      if (best == null || at.isAfter(best)) {
        best = at;
      }
    }
    return best ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  static int _compare(
    DiscoverableStoryCandidate a,
    DiscoverableStoryCandidate b,
    Map<String, DateTime> themeLastExpressedAt,
  ) {
    final overlap = b.themeOverlapCount.compareTo(a.themeOverlapCount);
    if (overlap != 0) {
      return overlap;
    }

    final recentA = _maxMatchedThemeExpressedAt(
      a.matchedThemeIds,
      themeLastExpressedAt,
    );
    final recentB = _maxMatchedThemeExpressedAt(
      b.matchedThemeIds,
      themeLastExpressedAt,
    );
    final recent = recentB.compareTo(recentA);
    if (recent != 0) {
      return recent;
    }

    final boost = b.patternBoost.compareTo(a.patternBoost);
    if (boost != 0) {
      return boost;
    }

    final updated = b.updatedAt.compareTo(a.updatedAt);
    if (updated != 0) {
      return updated;
    }

    return a.storyId.compareTo(b.storyId);
  }
}

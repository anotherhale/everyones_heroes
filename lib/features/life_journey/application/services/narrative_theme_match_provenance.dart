import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_discovery_signals.dart';
import 'package:everyonesheroes/features/life_journey/application/models/discoverable_story_candidate.dart';
import 'package:everyonesheroes/features/life_journey/application/models/narrative_theme_match_source.dart';

/// Derives theme-match explanation provenance from existing selection facts.
///
/// Uses [DiscoverableStoryCandidate.matchedThemeIds] against Inspiration and
/// Reflection theme sets already resolved into [AdaptiveDiscoverySignals].
/// Does not re-run eligibility, overlap, or ranking.
final class NarrativeThemeMatchProvenance {
  const NarrativeThemeMatchProvenance._();

  /// Reflection themes are those with a Reflection recency entry.
  /// Inspiration themes are [AdaptiveDiscoverySignals.inspirationThemeIds].
  static NarrativeThemeMatchSource resolve({
    required AdaptiveDiscoverySignals signals,
    required DiscoverableStoryCandidate candidate,
  }) {
    return resolveFromThemeIds(
      matchedThemeIds: candidate.matchedThemeIds,
      inspirationThemeIds: signals.inspirationThemeIds,
      reflectionThemeValues: signals.themeLastExpressedAt.keys,
    );
  }

  /// Pure source determination against matched theme IDs.
  ///
  /// ```text
  /// inspirationMatch = matched ∩ inspiration ≠ ∅
  /// reflectionMatch  = matched ∩ reflection  ≠ ∅
  /// ```
  static NarrativeThemeMatchSource resolveFromThemeIds({
    required List<NarrativeThemeId> matchedThemeIds,
    required List<NarrativeThemeId> inspirationThemeIds,
    required Iterable<String> reflectionThemeValues,
  }) {
    if (matchedThemeIds.isEmpty) {
      return NarrativeThemeMatchSource.unknown;
    }

    final inspirationValues = {
      for (final id in inspirationThemeIds) id.value,
    };
    final reflectionValues = reflectionThemeValues.toSet();

    var inspirationMatch = false;
    var reflectionMatch = false;

    for (final themeId in matchedThemeIds) {
      final value = themeId.value;
      if (inspirationValues.contains(value)) {
        inspirationMatch = true;
      }
      if (reflectionValues.contains(value)) {
        reflectionMatch = true;
      }
      if (inspirationMatch && reflectionMatch) {
        break;
      }
    }

    if (inspirationMatch && reflectionMatch) {
      return NarrativeThemeMatchSource.mixed;
    }
    if (inspirationMatch) {
      return NarrativeThemeMatchSource.inspiration;
    }
    if (reflectionMatch) {
      return NarrativeThemeMatchSource.reflection;
    }
    return NarrativeThemeMatchSource.unknown;
  }
}

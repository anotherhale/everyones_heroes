import 'package:everyonesheroes/features/life_journey/application/models/adaptive_discovery_signals.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_experience.dart';
import 'package:everyonesheroes/features/life_journey/application/models/discoverable_story_candidate.dart';
import 'package:everyonesheroes/features/life_journey/application/models/experience_action.dart';
import 'package:everyonesheroes/features/life_journey/application/models/experience_target.dart';
import 'package:everyonesheroes/features/life_journey/application/services/experience_selection_service.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/journey.dart';
import 'package:everyonesheroes/features/life_journey/domain/patterns/behavior_pattern_type.dart';

/// Composes Today's Experience from signals + Discover* candidates + UI.3 fallback.
///
/// Themes alone may select a Story. Patterns strengthen rationale/score but are
/// not a hard gate. No candidates → existing [ExperienceSelectionService].
final class AdaptiveExperienceComposer {
  const AdaptiveExperienceComposer({
    required this._reflectionSelectionService,
  });

  final ExperienceSelectionService _reflectionSelectionService;

  AdaptiveExperience compose({
    required Journey journey,
    required AdaptiveDiscoverySignals signals,
    required List<DiscoverableStoryCandidate> candidates,
  }) {
    final relevant = candidates
        .where((candidate) => candidate.themeOverlapCount > 0)
        .toList(growable: false);

    if (relevant.isEmpty) {
      return _reflectionSelectionService.selectFor(journey);
    }

    final top = relevant.first;
    return AdaptiveExperience(
      id: 'adaptive-story-${top.storyId.value}',
      type: ExperienceType.story,
      title: top.title,
      description:
          'A story that connects with themes you have been exploring '
          'on your journey.',
      action: ExperienceAction.begin,
      rationale: buildRationale(signals: signals, candidate: top),
      target: StoryExperienceTarget(storyId: top.storyId),
    );
  }

  /// Grounded rationale from actual matched signals only.
  static String buildRationale({
    required AdaptiveDiscoverySignals signals,
    required DiscoverableStoryCandidate candidate,
  }) {
    final hasPatterns = signals.hasPatterns && candidate.themeOverlapCount > 0;

    if (hasPatterns) {
      final patternLabel = _patternLabel(signals);
      return 'This story connects with themes you\'ve explored and '
          'patterns of $patternLabel in your journey.';
    }

    return 'This story connects with themes you\'ve recently reflected on.';
  }

  static String _patternLabel(AdaptiveDiscoverySignals signals) {
    final types = signals.behaviorPatterns.map((p) => p.type).toSet();
    if (types.contains(BehaviorPatternType.consistency)) {
      return 'consistency';
    }
    if (types.contains(BehaviorPatternType.discipline)) {
      return 'discipline';
    }
    if (types.contains(BehaviorPatternType.courage)) {
      return 'courage';
    }
    if (types.contains(BehaviorPatternType.resilience)) {
      return 'resilience';
    }
    // Deterministic: lowest enum name among remaining.
    final names = types.map((t) => t.name).toList()..sort();
    return names.first;
  }
}

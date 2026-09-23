import 'package:eh_platform/src/experience/application/models/adaptive_discovery_signals.dart';
import 'package:eh_platform/src/experience/application/models/discoverable_story_candidate.dart';
import 'package:eh_platform/src/experience/application/models/experience_action.dart';
import 'package:eh_platform/src/experience/application/models/experience_target.dart';
import 'package:eh_platform/src/experience/application/models/experience_type.dart';
import 'package:eh_platform/src/experience/application/models/selected_experience.dart';
import 'package:eh_platform/src/experience/application/services/experience_selection_service.dart';
import 'package:eh_platform/src/life_journey/domain/aggregates/journey.dart';
import 'package:eh_platform/src/life_journey/domain/patterns/behavior_pattern_type.dart';

/// HS.8 Adaptive Experience composition — ported from Flutter
/// `AdaptiveExperienceComposer`.
///
/// Theme-overlapping Story candidates win; otherwise UI.3 reflection selection.
/// Patterns strengthen rationale but are not a hard gate for Story.
final class AdaptiveExperienceComposer {
  const AdaptiveExperienceComposer({
    required ExperienceSelectionService reflectionSelectionService,
  }) : _reflectionSelectionService = reflectionSelectionService;

  final ExperienceSelectionService _reflectionSelectionService;

  SelectedExperience compose({
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
    final rationale = buildRationale(signals: signals, candidate: top);
    final themeSources = top.matchedThemeIds
        .map(
          (themeId) => ExplanationSource(
            kind: 'narrative_theme',
            value: themeId,
          ),
        )
        .toList(growable: false);

    return SelectedExperience(
      id: 'adaptive-story-${top.storyId}',
      type: ExperienceType.story,
      title: top.title,
      description:
          'A story that connects with themes you have been exploring '
          'on your journey.',
      action: ExperienceAction.begin,
      rationale: rationale,
      target: StoryExperienceTarget(storyId: top.storyId),
      explanationSources: themeSources,
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
    final names = types.map((t) => t.name).toList()..sort();
    return names.first;
  }
}

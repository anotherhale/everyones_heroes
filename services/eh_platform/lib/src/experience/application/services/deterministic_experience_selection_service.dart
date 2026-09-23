import 'package:eh_platform/src/experience/application/models/experience_action.dart';
import 'package:eh_platform/src/experience/application/models/experience_type.dart';
import 'package:eh_platform/src/experience/application/models/selected_experience.dart';
import 'package:eh_platform/src/experience/application/services/experience_selection_service.dart';
import 'package:eh_platform/src/life_journey/domain/aggregates/journey.dart';
import 'package:eh_platform/src/life_journey/domain/patterns/behavior_pattern_type.dart';

/// UI.3 deterministic selection — ported from Flutter
/// `DeterministicExperienceSelectionService`.
///
/// Mapping:
/// * consistency pattern → `consistency-next-step`
/// * otherwise → `default-reflection`
///
/// Consumes only [Journey.behaviorPatterns]. Does not read Mission/Quest.
final class DeterministicExperienceSelectionService
    implements ExperienceSelectionService {
  const DeterministicExperienceSelectionService();

  @override
  SelectedExperience selectFor(Journey journey) {
    final patterns = journey.behaviorPatterns;

    final consistency = patterns
        .where((pattern) => pattern.type == BehaviorPatternType.consistency)
        .firstOrNull;

    if (consistency != null) {
      return const SelectedExperience(
        id: 'consistency-next-step',
        type: ExperienceType.reflection,
        title: 'Keep Showing Up',
        description:
            'Take one small step today to strengthen the consistency '
            'you have already been building.',
        action: ExperienceAction.begin,
        rationale:
            'You have been building consistency across your recent journey.',
        explanationSources: [
          ExplanationSource(kind: 'behavior_pattern', value: 'consistency'),
        ],
      );
    }

    return const SelectedExperience(
      id: 'default-reflection',
      type: ExperienceType.reflection,
      title: 'Take the Next Step',
      description:
          'Take a moment to reflect on where you are and what matters '
          'most right now.',
      action: ExperienceAction.begin,
    );
  }
}

import 'package:everyonesheroes/features/life_journey/application/models/adaptive_experience.dart';
import 'package:everyonesheroes/features/life_journey/application/models/experience_action.dart';
import 'package:everyonesheroes/features/life_journey/application/services/experience_selection_service.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/journey.dart';
import 'package:everyonesheroes/features/life_journey/domain/patterns/behavior_pattern_type.dart';

final class DeterministicExperienceSelectionService
    implements ExperienceSelectionService {
  const DeterministicExperienceSelectionService();

  @override
  AdaptiveExperience selectFor(Journey journey) {
    final patterns = journey.behaviorPatterns;

    final consistency = patterns
        .where((pattern) => pattern.type == BehaviorPatternType.consistency)
        .firstOrNull;

    if (consistency != null) {
      return const AdaptiveExperience(
        id: 'consistency-next-step',
        type: ExperienceType.mission,
        title: 'Keep Showing Up',
        description:
            'Take one small step today to strengthen the consistency '
            'you have already been building.',
        action: ExperienceAction.begin,
        rationale:
            'You have been building consistency across your recent journey.',
      );
    }

    return const AdaptiveExperience(
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

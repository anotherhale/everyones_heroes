import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_step_type.dart';

/// One step in a Story Experience Plan sequence (HS.12.4).
///
/// [referenceId] points at a plan element when needed (e.g. a key moment id).
final class StoryExperienceStep extends ValueObject {
  const StoryExperienceStep({
    required this.type,
    this.referenceId,
  });

  final StoryExperienceStepType type;
  final String? referenceId;

  @override
  List<Object?> get equalityProps => [type, referenceId];
}

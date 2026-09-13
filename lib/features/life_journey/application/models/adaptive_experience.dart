import 'package:everyonesheroes/features/life_journey/application/models/experience_action.dart';
import 'package:everyonesheroes/features/life_journey/application/models/experience_target.dart';

enum ExperienceType { mission, reflection, story, coaching, discovery }

final class AdaptiveExperience {
  const AdaptiveExperience({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.action,
    this.rationale,
    this.target,
  });

  final String id;
  final ExperienceType type;
  final String title;
  final String description;
  final ExperienceAction action;
  final String? rationale;

  /// Typed target for non-reflection experiences (HS.8: Story only).
  final ExperienceTarget? target;
}

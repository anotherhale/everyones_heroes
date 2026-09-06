import 'package:everyonesheroes/features/life_journey/application/models/experience_action.dart';

enum ExperienceType { mission, reflection, story, coaching, discovery }

final class AdaptiveExperience {
  const AdaptiveExperience({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.action,
    this.rationale,
  });

  final String id;
  final ExperienceType type;
  final String title;
  final String description;
  final ExperienceAction action;
  final String? rationale;
}

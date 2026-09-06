import 'package:everyonesheroes/features/life_journey/application/models/adaptive_experience.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/journey.dart';

abstract interface class ExperienceSelectionService {
  AdaptiveExperience selectFor(Journey journey);
}

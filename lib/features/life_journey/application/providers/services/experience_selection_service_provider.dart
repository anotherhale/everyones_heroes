import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/life_journey/application/services/deterministic_experience_selection_service.dart';
import 'package:everyonesheroes/features/life_journey/application/services/experience_selection_service.dart';

final experienceSelectionServiceProvider =
    Provider<ExperienceSelectionService>((ref) {
  return const DeterministicExperienceSelectionService();
});

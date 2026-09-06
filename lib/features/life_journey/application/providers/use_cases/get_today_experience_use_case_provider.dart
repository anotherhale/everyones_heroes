import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/life_journey/application/providers/context/current_journey_context_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/repositories/journey_repository_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/services/experience_selection_service_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/get_today_experience_use_case.dart';

final getTodayExperienceUseCaseProvider =
    Provider<GetTodayExperienceUseCase>((ref) {
  return DefaultGetTodayExperienceUseCase(
    journeyRepository: ref.read(journeyRepositoryProvider),
    currentJourneyContext: ref.read(currentJourneyContextProvider),
    experienceSelectionService:
        ref.read(experienceSelectionServiceProvider),
  );
});

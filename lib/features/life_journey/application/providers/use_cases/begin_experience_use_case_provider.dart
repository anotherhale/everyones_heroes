import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/life_journey/application/dto/requests/create_reflection_request.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/context/current_journey_context_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/use_cases/create_reflection_use_case_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/begin_experience_use_case.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';

final beginExperienceUseCaseProvider = Provider<BeginExperienceUseCase>((ref) {
  final createReflectionUseCase = ref.read(createReflectionUseCaseProvider);

  return DefaultBeginExperienceUseCase(
    currentJourneyContext: ref.read(currentJourneyContextProvider),
    createReflectionUseCase:
        createReflectionUseCase as UseCase<CreateReflectionRequest, Reflection>,
  );
});

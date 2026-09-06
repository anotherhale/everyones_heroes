import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/eventing/event_providers.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/create_journey_use_case.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/repositories/journey_repository_provider.dart';

final createJourneyUseCaseProvider = Provider<CreateJourneyUseCase>((ref) {
  return CreateJourneyUseCase(
    journeyRepository: ref.read(journeyRepositoryProvider),
    eventBus: ref.read(eventBusProvider),
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/features/life_journey/application/dto/requests/create_journey_request.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/context/current_journey_context_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/use_cases/create_journey_use_case_provider.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/journey_vision.dart';

final class DemoRunner {
  const DemoRunner({required this.container});

  final ProviderContainer container;

  Future<void> run() async {
    final currentJourneyContext = container.read(currentJourneyContextProvider);

    if (currentJourneyContext.currentJourneyId != null) {
      return;
    }

    final createJourney = container.read(createJourneyUseCaseProvider);

    final result = await createJourney.execute(
      CreateJourneyRequest(
        journeyId: JourneyId.generate(),
        vision: JourneyVision('Become the person I want to be.'),
      ),
    );

    result.fold(
      onSuccess: (journey) {
        currentJourneyContext.setCurrentJourney(journey.id);
      },
      onFailure: (error) {
        throw StateError(error);
      },
    );
  }
}

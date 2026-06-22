import 'package:everyonesheroes/core/ids/journey_id.dart';

import 'package:everyonesheroes/features/life_journey/domain/value_objects/journey_vision.dart';

final class CreateJourneyRequest {
  const CreateJourneyRequest({required this.journeyId, required this.vision});

  final JourneyId journeyId;

  final JourneyVision vision;
}

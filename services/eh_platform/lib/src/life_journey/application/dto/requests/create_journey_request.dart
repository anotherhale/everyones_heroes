import 'package:eh_platform/src/shared_kernel/ids/journey_id.dart';

import 'package:eh_platform/src/life_journey/domain/value_objects/journey_vision.dart';

final class CreateJourneyRequest {
  const CreateJourneyRequest({required this.journeyId, required this.vision});

  final JourneyId journeyId;

  final JourneyVision vision;
}

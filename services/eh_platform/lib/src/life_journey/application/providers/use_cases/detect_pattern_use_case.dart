import 'package:eh_platform/src/shared_kernel/ids/journey_id.dart';
import 'package:eh_platform/src/life_journey/application/use_cases/use_case.dart';
import 'package:eh_platform/src/life_journey/domain/domain.dart';

abstract interface class DetectPatternUseCase
    implements UseCase<JourneyId, List<BehaviorPattern>> {}

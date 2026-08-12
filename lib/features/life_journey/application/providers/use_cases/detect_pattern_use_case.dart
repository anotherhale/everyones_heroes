import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/life_journey/domain/domain.dart';

abstract interface class DetectPatternUseCase
    implements UseCase<JourneyId, List<BehaviorPattern>> {}

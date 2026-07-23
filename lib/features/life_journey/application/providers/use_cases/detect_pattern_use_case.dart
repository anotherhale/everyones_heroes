import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/features/life_journey/domain/domain.dart';

abstract interface class DetectPatternsUseCase {
  List<BehaviorPattern> call({required JourneyId journeyId});
}

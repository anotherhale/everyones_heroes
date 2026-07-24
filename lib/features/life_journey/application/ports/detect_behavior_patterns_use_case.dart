import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/features/life_journey/domain/domain.dart';

abstract interface class DetectBehaviorPatternsUseCase {
  Future<List<BehaviorPattern>> call({required JourneyId journeyId});
}

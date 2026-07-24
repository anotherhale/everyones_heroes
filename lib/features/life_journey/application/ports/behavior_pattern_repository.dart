import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/features/life_journey/domain/domain.dart';

abstract interface class BehaviorPatternRepository {
  Future<void> saveAll(JourneyId journeyId, Iterable<BehaviorPattern> patterns);

  Future<List<BehaviorPattern>> findByJourney(JourneyId journeyId);
}

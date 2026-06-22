import 'package:everyonesheroes/core/ids/journey_id.dart';

import 'package:everyonesheroes/features/life_journey/domain/aggregates/journey.dart';

abstract interface class JourneyRepository {
  Future<void> save(Journey journey);

  Future<Journey?> findById(
    JourneyId id,
  );

  Future<bool> exists(
    JourneyId id,
  );

  Future<void> delete(
    JourneyId id,
  );
}
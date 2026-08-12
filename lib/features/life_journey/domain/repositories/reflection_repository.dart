import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';

abstract interface class ReflectionRepository {
  Future<void> save(Reflection reflection);

  Future<Reflection?> findById(ReflectionId id);

  Future<List<Reflection>> findByJourneyId(JourneyId journeyId);

  Future<bool> exists(ReflectionId id);

  Future<void> delete(ReflectionId id);
}

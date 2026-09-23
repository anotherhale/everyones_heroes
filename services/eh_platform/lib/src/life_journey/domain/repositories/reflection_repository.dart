import 'package:eh_platform/src/shared_kernel/ids/journey_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/reflection_id.dart';
import 'package:eh_platform/src/life_journey/domain/aggregates/reflection.dart';

abstract interface class ReflectionRepository {
  Future<void> save(Reflection reflection);

  Future<Reflection?> findById(ReflectionId id);

  Future<List<Reflection>> findByJourneyId(JourneyId journeyId);

  Future<bool> exists(ReflectionId id);

  Future<void> delete(ReflectionId id);
}

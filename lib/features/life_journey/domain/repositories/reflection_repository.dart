import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';

abstract interface class ReflectionRepository {
  Future<void> save(
    Reflection reflection,
  );

  Future<Reflection?> findById(
    ReflectionId id,
  );

  Future<bool> exists(
    ReflectionId id,
  );

  Future<void> delete(
    ReflectionId id,
  );
}
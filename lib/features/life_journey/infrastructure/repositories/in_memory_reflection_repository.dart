
import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';
import 'package:everyonesheroes/features/life_journey/domain/repositories/reflection_repository.dart';

final class InMemoryReflectionRepository
    implements ReflectionRepository {
  final Map<ReflectionId, Reflection> _storage = {};

  @override
  Future<void> save(
    Reflection reflection,
  ) async {
    _storage[reflection.id] = reflection;
  }

  @override
  Future<Reflection?> findById(
    ReflectionId id,
  ) async {
    return _storage[id];
  }

  @override
  Future<bool> exists(
    ReflectionId id,
  ) async {
    return _storage.containsKey(id);
  }

  @override
  Future<void> delete(
    ReflectionId id,
  ) async {
    _storage.remove(id);
  }
}
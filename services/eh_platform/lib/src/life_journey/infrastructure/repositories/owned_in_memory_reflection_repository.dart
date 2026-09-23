import 'package:eh_platform/src/life_journey/domain/aggregates/reflection.dart';
import 'package:eh_platform/src/life_journey/domain/repositories/reflection_repository.dart';
import 'package:eh_platform/src/shared_kernel/ids/journey_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/reflection_id.dart';
import 'package:eh_platform/src/shared_kernel/user_id.dart';

/// In-memory Reflection repository with user ownership.
final class OwnedInMemoryReflectionRepository implements ReflectionRepository {
  final Map<ReflectionId, Reflection> _store = {};
  final Map<ReflectionId, UserId> _owners = {};

  Future<void> saveForUser(Reflection reflection, UserId userId) async {
    _store[reflection.id] = reflection;
    _owners[reflection.id] = userId;
  }

  @override
  Future<void> save(Reflection reflection) async {
    if (!_owners.containsKey(reflection.id)) {
      throw StateError(
        'Cannot save new Reflection without user ownership. Use saveForUser.',
      );
    }
    _store[reflection.id] = reflection;
  }

  @override
  Future<Reflection?> findById(ReflectionId id) async => _store[id];

  @override
  Future<List<Reflection>> findByJourneyId(JourneyId journeyId) async {
    return _store.values
        .where((r) => r.journeyId == journeyId)
        .toList(growable: false);
  }

  Future<UserId?> ownerOf(ReflectionId id) async => _owners[id];

  @override
  Future<bool> exists(ReflectionId id) async => _store.containsKey(id);

  @override
  Future<void> delete(ReflectionId id) async {
    _store.remove(id);
    _owners.remove(id);
  }
}

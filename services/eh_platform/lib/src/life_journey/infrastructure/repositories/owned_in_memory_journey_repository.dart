import 'package:eh_platform/src/life_journey/domain/aggregates/journey.dart';
import 'package:eh_platform/src/life_journey/domain/repositories/journey_repository.dart';
import 'package:eh_platform/src/shared_kernel/ids/journey_id.dart';
import 'package:eh_platform/src/shared_kernel/user_id.dart';

/// In-memory Journey repository with user ownership (test / non-Postgres).
final class OwnedInMemoryJourneyRepository implements JourneyRepository {
  final Map<JourneyId, Journey> _store = {};
  final Map<JourneyId, UserId> _owners = {};
  final Map<UserId, JourneyId> _currentByUser = {};

  Future<void> saveForUser(Journey journey, UserId userId) async {
    _store[journey.id] = journey;
    _owners[journey.id] = userId;
    _currentByUser[userId] = journey.id;
  }

  @override
  Future<void> save(Journey journey) async {
    if (!_owners.containsKey(journey.id)) {
      throw StateError(
        'Cannot save new Journey without user ownership. Use saveForUser.',
      );
    }
    _store[journey.id] = journey;
  }

  @override
  Future<Journey?> findById(JourneyId id) async => _store[id];

  Future<Journey?> findCurrentByUserId(UserId userId) async {
    final id = _currentByUser[userId];
    if (id == null) {
      return null;
    }
    return _store[id];
  }

  Future<UserId?> ownerOf(JourneyId id) async => _owners[id];

  @override
  Future<bool> exists(JourneyId id) async => _store.containsKey(id);

  @override
  Future<void> delete(JourneyId id) async {
    final owner = _owners.remove(id);
    _store.remove(id);
    if (owner != null && _currentByUser[owner] == id) {
      _currentByUser.remove(owner);
    }
  }
}

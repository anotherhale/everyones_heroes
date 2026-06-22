import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/journey.dart';
import 'package:everyonesheroes/features/life_journey/domain/repositories/journey_repository.dart';

class InMemoryJourneyRepository implements JourneyRepository {
  final Map<JourneyId, Journey> _store = {};

  @override
  Future<void> save(Journey journey) async {
    _store[journey.id] = journey;
  }

  @override
  Future<Journey?> findById(JourneyId id) async {
    return _store[id];
  }

  @override
  Future<bool> exists(JourneyId id) async {
    return _store.containsKey(id);
  }

  @override
  Future<void> delete(JourneyId id) async {
    _store.remove(id);
  }
}

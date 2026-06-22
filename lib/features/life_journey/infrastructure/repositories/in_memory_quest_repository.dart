import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/quest_id.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/quest.dart';
import 'package:everyonesheroes/features/life_journey/domain/repositories/quest_repository.dart';

class InMemoryQuestRepository implements QuestRepository {
  final Map<QuestId, Quest> _store = {};

  @override
  Future<void> save(Quest quest) async {
    _store[quest.id] = quest;
  }

  @override
  Future<Quest?> findById(QuestId id) async {
    return _store[id];
  }

  @override
  Future<bool> exists(QuestId id) async {
    return _store.containsKey(id);
  }

  @override
  Future<void> delete(QuestId id) async {
    _store.remove(id);
  }

  @override
  Future<List<Quest>> findByJourneyId(JourneyId journeyId) async {
    return _store.values
        .where((quest) => quest.journeyId == journeyId)
        .toList(growable: false);
  }
}

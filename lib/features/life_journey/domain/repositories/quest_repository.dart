import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/quest_id.dart';

import 'package:everyonesheroes/features/life_journey/domain/aggregates/quest.dart';

abstract interface class QuestRepository {
  Future<void> save(Quest quest);

  Future<Quest?> findById(
    QuestId id,
  );

  Future<List<Quest>> findByJourneyId(
    JourneyId journeyId,
  );

  Future<bool> exists(
    QuestId id,
  );

  Future<void> delete(
    QuestId id,
  );
}
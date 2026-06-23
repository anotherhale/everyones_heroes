import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/quest_id.dart';

import 'package:everyonesheroes/features/life_journey/domain/value_objects/quest_title.dart';

final class CreateQuestRequest {
  const CreateQuestRequest({
    required this.questId,
    required this.journeyId,
    required this.title,
  });

  final QuestId questId;

  final JourneyId journeyId;

  final QuestTitle title;
}

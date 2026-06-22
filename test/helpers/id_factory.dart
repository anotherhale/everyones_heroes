import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/mission_id.dart';
import 'package:everyonesheroes/core/ids/quest_id.dart';

class IdFactory {
  const IdFactory._();

  static JourneyId journey() {
    return JourneyId.generate();
  }

  static QuestId quest() {
    return QuestId.generate();
  }

  static MissionId mission() {
    return MissionId.generate();
  }
}
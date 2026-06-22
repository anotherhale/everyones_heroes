import 'package:everyonesheroes/core/eventing/event_base.dart';
import 'package:everyonesheroes/core/ids/journey_id.dart';

final class QuestCompleted extends EventBase {
  QuestCompleted({
    required super.aggregateId,
    required this.journeyId,
    super.correlationId,
    super.causationId,
  }) : super(
          aggregateType: 'Quest',
        );

  final JourneyId journeyId;
}
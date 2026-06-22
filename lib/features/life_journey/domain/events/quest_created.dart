import 'package:everyonesheroes/core/eventing/event_base.dart';
import 'package:everyonesheroes/core/ids/journey_id.dart';


final class QuestCreated extends EventBase {
  QuestCreated({
    required super.aggregateId,
    required this.journeyId,
    super.correlationId,
    super.causationId,
  }) : super(
          aggregateType: 'Quest',
        );

  final JourneyId journeyId;
}
import 'package:everyonesheroes/core/eventing/event_base.dart';
import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/aggregate_type.dart';

final class QuestCreated extends EventBase {
  QuestCreated({
    required super.aggregateId,
    required this.journeyId,
    super.correlationId,
    super.causationId,
  }) : super(aggregateType: AggregateType.quest);

  final JourneyId journeyId;
}

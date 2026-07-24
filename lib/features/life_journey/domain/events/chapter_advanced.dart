import 'package:everyonesheroes/core/eventing/event_base.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/aggregate_type.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/journey_chapter.dart';

final class ChapterAdvanced extends EventBase {
  ChapterAdvanced({
    required super.aggregateId,
    required this.previousChapter,
    required this.newChapter,
    super.correlationId,
    super.causationId,
  }) : super(aggregateType: AggregateType.journey);

  final JourneyChapter previousChapter;

  final JourneyChapter newChapter;
}

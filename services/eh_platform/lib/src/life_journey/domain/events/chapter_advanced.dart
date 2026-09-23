import 'package:eh_platform/src/eventing/event_base.dart';
import 'package:eh_platform/src/eventing/aggregate_type.dart';
import 'package:eh_platform/src/life_journey/domain/enums/journey_chapter.dart';

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

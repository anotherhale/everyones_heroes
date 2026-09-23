import 'package:eh_platform/src/life_journey/domain/enums/journey_chapter.dart';
import 'package:eh_platform/src/life_journey/domain/events/life_journey_event.dart';
import 'package:eh_platform/src/shared_kernel/ids/journey_id.dart';

final class ChapterAdvanced extends LifeJourneyEvent {
  ChapterAdvanced({
    required JourneyId aggregateId,
    required this.previousChapter,
    required this.newChapter,
    super.eventId,
    super.occurredAt,
    super.correlationId,
    super.causationId,
  }) : super(
          aggregateId: aggregateId.value,
          aggregateType: 'journey',
          eventName: 'ChapterAdvanced',
        );

  final JourneyChapter previousChapter;
  final JourneyChapter newChapter;
}

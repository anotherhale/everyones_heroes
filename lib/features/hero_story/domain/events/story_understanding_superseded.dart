import 'package:everyonesheroes/core/eventing/aggregate_type.dart';
import 'package:everyonesheroes/core/eventing/event_base.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_understanding_id.dart';

final class StoryUnderstandingSuperseded extends EventBase {
  StoryUnderstandingSuperseded({
    required StoryUnderstandingId understandingId,
    required this.storyId,
    required this.supersededByUnderstandingId,
    super.correlationId,
    super.causationId,
  }) : understandingId = understandingId,
       super(
         aggregateId: understandingId,
         aggregateType: AggregateType.storyUnderstanding,
       );

  final StoryUnderstandingId understandingId;
  final StoryId storyId;
  final StoryUnderstandingId supersededByUnderstandingId;
}

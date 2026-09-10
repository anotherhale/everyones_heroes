import 'package:everyonesheroes/core/eventing/aggregate_type.dart';
import 'package:everyonesheroes/core/eventing/event_base.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';

final class StoryClassified extends EventBase {
  StoryClassified({
    required StoryId storyId,
    super.correlationId,
    super.causationId,
  }) : storyId = storyId,
       super(aggregateId: storyId, aggregateType: AggregateType.story);

  final StoryId storyId;
}

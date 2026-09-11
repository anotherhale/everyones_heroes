import 'package:everyonesheroes/core/eventing/aggregate_type.dart';
import 'package:everyonesheroes/core/eventing/event_base.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';

final class StoryPublished extends EventBase {
  StoryPublished({
    required StoryId storyId,
    required this.heroId,
    super.correlationId,
    super.causationId,
  }) : storyId = storyId,
       super(aggregateId: storyId, aggregateType: AggregateType.story);

  final StoryId storyId;
  final HeroId heroId;
}

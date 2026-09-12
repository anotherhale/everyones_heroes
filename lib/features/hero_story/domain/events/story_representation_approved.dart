import 'package:everyonesheroes/core/eventing/aggregate_type.dart';
import 'package:everyonesheroes/core/eventing/event_base.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';

/// Raised when an AI-derived StoryRepresentation becomes authoritative.
final class StoryRepresentationApproved extends EventBase {
  StoryRepresentationApproved({
    required StoryId storyId,
    required this.representationId,
    super.correlationId,
    super.causationId,
  }) : storyId = storyId,
       super(aggregateId: storyId, aggregateType: AggregateType.story);

  final StoryId storyId;
  final StoryRepresentationId representationId;
}

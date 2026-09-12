import 'package:everyonesheroes/core/eventing/aggregate_type.dart';
import 'package:everyonesheroes/core/eventing/event_base.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_understanding_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/understanding_review_decision.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/understanding_status.dart';

final class StoryUnderstandingReviewed extends EventBase {
  StoryUnderstandingReviewed({
    required StoryUnderstandingId understandingId,
    required this.storyId,
    required this.decision,
    required this.status,
    super.correlationId,
    super.causationId,
  }) : understandingId = understandingId,
       super(
         aggregateId: understandingId,
         aggregateType: AggregateType.storyUnderstanding,
       );

  final StoryUnderstandingId understandingId;
  final StoryId storyId;
  final UnderstandingReviewDecision decision;
  final UnderstandingStatus status;
}

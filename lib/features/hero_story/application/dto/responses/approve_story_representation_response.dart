import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';

final class ApproveStoryRepresentationResponse {
  const ApproveStoryRepresentationResponse({
    required this.story,
    required this.storyId,
    required this.representationId,
    this.idempotentReplay = false,
  });

  final Story story;
  final StoryId storyId;
  final StoryRepresentationId representationId;
  final bool idempotentReplay;
}

import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';

final class CompleteStoryCaptureResponse {
  const CompleteStoryCaptureResponse({
    required this.story,
    required this.storyId,
    required this.representationId,
    required this.mediaReference,
    required this.createdStory,
    required this.idempotentReplay,
  });

  final Story story;
  final StoryId storyId;
  final StoryRepresentationId representationId;
  final MediaReference mediaReference;
  final bool createdStory;
  final bool idempotentReplay;
}

import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_narrative.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_title.dart';

final class UpdateStoryNarrativeRequest {
  const UpdateStoryNarrativeRequest({
    required this.storyId,
    this.title,
    this.narrative,
    this.occurredAt,
  });

  final StoryId storyId;
  final StoryTitle? title;
  final StoryNarrative? narrative;
  final DateTime? occurredAt;
}

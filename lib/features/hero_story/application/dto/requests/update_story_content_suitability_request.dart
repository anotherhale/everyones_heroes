import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/content_suitability.dart';

final class UpdateStoryContentSuitabilityRequest {
  const UpdateStoryContentSuitabilityRequest({
    required this.storyId,
    required this.contentSuitability,
  });

  final StoryId storyId;
  final ContentSuitability contentSuitability;
}

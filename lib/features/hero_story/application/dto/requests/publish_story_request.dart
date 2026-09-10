import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_visibility.dart';

final class PublishStoryRequest {
  const PublishStoryRequest({
    required this.storyId,
    this.visibility,
  });

  final StoryId storyId;

  /// Optional visibility applied before publishing.
  final StoryVisibility? visibility;
}

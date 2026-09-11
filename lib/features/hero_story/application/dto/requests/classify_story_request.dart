import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_classification.dart';

final class ClassifyStoryRequest {
  const ClassifyStoryRequest({
    required this.storyId,
    required this.classification,
  });

  final StoryId storyId;
  final StoryClassification classification;
}

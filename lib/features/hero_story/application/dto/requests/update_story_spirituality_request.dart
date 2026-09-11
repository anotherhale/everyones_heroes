import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/spirituality_classification.dart';

final class UpdateStorySpiritualityRequest {
  const UpdateStorySpiritualityRequest({
    required this.storyId,
    required this.spirituality,
  });

  final StoryId storyId;
  final SpiritualityClassification spirituality;
}

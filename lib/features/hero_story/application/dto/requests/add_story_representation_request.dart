import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/entities/story_representation.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_transformation_type.dart';

final class AddStoryRepresentationRequest {
  const AddStoryRepresentationRequest({
    required this.storyId,
    required this.representation,
    this.transformationType = StoryTransformationType.other,
  });

  final StoryId storyId;
  final StoryRepresentation representation;
  final StoryTransformationType transformationType;
}

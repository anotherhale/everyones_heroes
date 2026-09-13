import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';

/// Loads media bytes for an authoritative, discoverable representation.
final class LoadStoryMediaRequest {
  const LoadStoryMediaRequest({
    required this.storyId,
    required this.representationId,
  });

  final StoryId storyId;
  final StoryRepresentationId representationId;
}

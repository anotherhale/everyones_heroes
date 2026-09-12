import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';

final class EditUnapprovedStoryRepresentationRequest {
  const EditUnapprovedStoryRepresentationRequest({
    required this.storyId,
    required this.representationId,
    required this.textContent,
    this.occurredAt,
  });

  final StoryId storyId;
  final StoryRepresentationId representationId;
  final String textContent;
  final DateTime? occurredAt;
}

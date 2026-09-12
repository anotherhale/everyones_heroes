import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';

final class ApproveStoryRepresentationRequest {
  const ApproveStoryRepresentationRequest({
    required this.storyId,
    required this.representationId,
    this.requestId,
    this.occurredAt,
  });

  final StoryId storyId;
  final StoryRepresentationId representationId;
  final String? requestId;
  final DateTime? occurredAt;
}

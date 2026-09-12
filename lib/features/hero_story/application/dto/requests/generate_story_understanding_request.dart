import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/ids/story_understanding_id.dart';

final class GenerateStoryUnderstandingRequest {
  const GenerateStoryUnderstandingRequest({
    required this.storyId,
    required this.sourceRepresentationIds,
    required this.requestId,
    required this.understandingId,
    this.processingVersion = 'hs4-v1',
    this.occurredAt,
  });

  final StoryId storyId;
  final List<StoryRepresentationId> sourceRepresentationIds;
  final String requestId;
  final StoryUnderstandingId understandingId;
  final String processingVersion;
  final DateTime? occurredAt;
}

import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';

final class TranscribeStoryRequest {
  const TranscribeStoryRequest({
    required this.storyId,
    required this.sourceRepresentationId,
    required this.requestId,
    required this.transcriptRepresentationId,
    this.processingVersion = 'hs4-v1',
    this.occurredAt,
  });

  final StoryId storyId;
  final StoryRepresentationId sourceRepresentationId;
  final String requestId;
  final StoryRepresentationId transcriptRepresentationId;
  final String processingVersion;
  final DateTime? occurredAt;
}

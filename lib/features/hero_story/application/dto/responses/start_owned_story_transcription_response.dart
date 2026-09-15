import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_transcription_job_status.dart';

final class StartOwnedStoryTranscriptionResponse {
  const StartOwnedStoryTranscriptionResponse({
    required this.storyId,
    required this.sourceRepresentationId,
    required this.status,
    required this.requestId,
    this.transcriptRepresentationId,
    this.transcriptText,
    this.errorMessage,
    this.failureKind,
    this.idempotentReplay = false,
  });

  final StoryId storyId;
  final StoryRepresentationId sourceRepresentationId;
  final StoryTranscriptionJobStatus status;
  final String requestId;
  final StoryRepresentationId? transcriptRepresentationId;
  final String? transcriptText;
  final String? errorMessage;
  final String? failureKind;
  final bool idempotentReplay;
}

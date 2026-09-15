import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_transcription_job_status.dart';

/// Owner-facing transcription processing status for Story Detail (HS.11).
final class OwnedStoryTranscriptionStatus {
  const OwnedStoryTranscriptionStatus({
    required this.storyId,
    required this.status,
    required this.hasAiProcessingConsent,
    required this.canStart,
    required this.canRetry,
    this.sourceRepresentationId,
    this.transcriptRepresentationId,
    this.transcriptText,
    this.transcriptIsAiGenerated = false,
    this.transcriptIsApproved = false,
    this.errorMessage,
    this.failureKind,
    this.requestId,
  });

  final StoryId storyId;
  final StoryTranscriptionJobStatus status;
  final StoryRepresentationId? sourceRepresentationId;
  final StoryRepresentationId? transcriptRepresentationId;
  final String? transcriptText;
  final bool transcriptIsAiGenerated;
  final bool transcriptIsApproved;
  final bool hasAiProcessingConsent;
  final bool canStart;
  final bool canRetry;
  final String? errorMessage;
  final String? failureKind;
  final String? requestId;
}

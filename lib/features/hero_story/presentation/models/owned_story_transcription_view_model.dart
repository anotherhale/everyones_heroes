import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/owned_story_transcription_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_transcription_job_status.dart';
import 'package:everyonesheroes/features/hero_story/presentation/models/owned_story_labels.dart';

/// Presentation model for owner transcription UI (HS.11).
final class OwnedStoryTranscriptionViewModel {
  const OwnedStoryTranscriptionViewModel({
    required this.storyId,
    required this.status,
    required this.statusLabel,
    required this.hasAiProcessingConsent,
    required this.canStart,
    required this.canRetry,
    required this.showProcessing,
    required this.showTranscript,
    this.sourceRepresentationId,
    this.transcriptRepresentationId,
    this.transcriptText,
    this.transcriptIsApproved = false,
    this.errorMessage,
  });

  final StoryId storyId;
  final StoryTranscriptionJobStatus status;
  final String statusLabel;
  final bool hasAiProcessingConsent;
  final bool canStart;
  final bool canRetry;
  final bool showProcessing;
  final bool showTranscript;
  final StoryRepresentationId? sourceRepresentationId;
  final StoryRepresentationId? transcriptRepresentationId;
  final String? transcriptText;
  final bool transcriptIsApproved;
  final String? errorMessage;

  factory OwnedStoryTranscriptionViewModel.fromStatus(
    OwnedStoryTranscriptionStatus status,
  ) {
    return OwnedStoryTranscriptionViewModel(
      storyId: status.storyId,
      status: status.status,
      statusLabel: OwnedStoryLabels.transcriptionStatusLabel(status.status),
      hasAiProcessingConsent: status.hasAiProcessingConsent,
      canStart: status.canStart,
      canRetry: status.canRetry,
      showProcessing: status.status == StoryTranscriptionJobStatus.inProgress,
      showTranscript: status.status == StoryTranscriptionJobStatus.completed &&
          (status.transcriptText?.trim().isNotEmpty ?? false),
      sourceRepresentationId: status.sourceRepresentationId,
      transcriptRepresentationId: status.transcriptRepresentationId,
      transcriptText: status.transcriptText,
      transcriptIsApproved: status.transcriptIsApproved,
      errorMessage: status.errorMessage,
    );
  }
}

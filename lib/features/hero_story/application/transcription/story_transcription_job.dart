import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_transcription_job_status.dart';

/// Durable application record for owner transcription processing (HS.11).
///
/// Keyed by [storyId] + [sourceRepresentationId]. Retry after [failed]
/// reuses this record with a new [requestId] / attempt — it does not create
/// unbounded concurrent jobs or replace the original recording.
final class StoryTranscriptionJob {
  const StoryTranscriptionJob({
    required this.storyId,
    required this.sourceRepresentationId,
    required this.status,
    required this.requestId,
    required this.updatedAt,
    this.transcriptRepresentationId,
    this.errorMessage,
    this.failureKind,
    this.startedAt,
    this.completedAt,
    this.attempt = 1,
  });

  final StoryId storyId;
  final StoryRepresentationId sourceRepresentationId;
  final StoryTranscriptionJobStatus status;
  final String requestId;
  final StoryRepresentationId? transcriptRepresentationId;
  final String? errorMessage;

  /// Application-level failure category (not a vendor code).
  final String? failureKind;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime updatedAt;
  final int attempt;

  String get storageKey => jobKey(storyId, sourceRepresentationId);

  static String jobKey(
    StoryId storyId,
    StoryRepresentationId sourceRepresentationId,
  ) =>
      '${storyId.value}::${sourceRepresentationId.value}';

  StoryTranscriptionJob copyWith({
    StoryTranscriptionJobStatus? status,
    String? requestId,
    StoryRepresentationId? transcriptRepresentationId,
    String? errorMessage,
    String? failureKind,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? updatedAt,
    int? attempt,
    bool clearError = false,
    bool clearTranscript = false,
  }) {
    return StoryTranscriptionJob(
      storyId: storyId,
      sourceRepresentationId: sourceRepresentationId,
      status: status ?? this.status,
      requestId: requestId ?? this.requestId,
      transcriptRepresentationId: clearTranscript
          ? null
          : (transcriptRepresentationId ?? this.transcriptRepresentationId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      failureKind: clearError ? null : (failureKind ?? this.failureKind),
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attempt: attempt ?? this.attempt,
    );
  }
}

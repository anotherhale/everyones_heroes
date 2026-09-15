import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/features/hero_story/application/transcription/story_transcription_job.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_transcription_job_status.dart';

/// Application store for transcription job status (HS.11 / HS-ADR-070).
///
/// Not a domain repository. Survives restart when backed by a file adapter.
abstract interface class StoryTranscriptionJobStore {
  StoryTranscriptionJob? find({
    required StoryId storyId,
    required StoryRepresentationId sourceRepresentationId,
  });

  /// Returns all jobs for a Story (typically one primary original recording).
  List<StoryTranscriptionJob> findByStory(StoryId storyId);

  void save(StoryTranscriptionJob job);

  void remove({
    required StoryId storyId,
    required StoryRepresentationId sourceRepresentationId,
  });
}

final class InMemoryStoryTranscriptionJobStore
    implements StoryTranscriptionJobStore {
  final Map<String, StoryTranscriptionJob> _byKey = {};

  @override
  StoryTranscriptionJob? find({
    required StoryId storyId,
    required StoryRepresentationId sourceRepresentationId,
  }) {
    return _byKey[StoryTranscriptionJob.jobKey(storyId, sourceRepresentationId)];
  }

  @override
  List<StoryTranscriptionJob> findByStory(StoryId storyId) {
    return _byKey.values
        .where((job) => job.storyId == storyId)
        .toList(growable: false);
  }

  @override
  void save(StoryTranscriptionJob job) {
    _byKey[job.storageKey] = job;
  }

  @override
  void remove({
    required StoryId storyId,
    required StoryRepresentationId sourceRepresentationId,
  }) {
    _byKey.remove(
      StoryTranscriptionJob.jobKey(storyId, sourceRepresentationId),
    );
  }
}

/// Maps infrastructure/provider failures into EH-owned failure kinds for UI.
abstract final class TranscriptionFailureKind {
  static const storyNotFound = 'story_not_found';
  static const notOwned = 'not_owned';
  static const recordingUnavailable = 'recording_unavailable';
  static const consentMissing = 'consent_missing';
  static const unsupportedMedia = 'unsupported_media';
  static const alreadyInProgress = 'already_in_progress';
  static const alreadyCompleted = 'already_completed';
  static const providerFailure = 'provider_failure';
  static const networkFailure = 'network_failure';
  static const timeout = 'timeout';
  static const malformedResponse = 'malformed_response';
  static const persistenceFailure = 'persistence_failure';
  static const emptyTranscript = 'empty_transcript';
  static const unknown = 'unknown';

  static String fromMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('not found') && lower.contains('story')) {
      return storyNotFound;
    }
    if (lower.contains('not owned')) {
      return notOwned;
    }
    if (lower.contains('consent')) {
      return consentMissing;
    }
    if (lower.contains('media') &&
        (lower.contains('missing') ||
            lower.contains('empty') ||
            lower.contains('unavailable') ||
            lower.contains('no media'))) {
      return recordingUnavailable;
    }
    if (lower.contains('unsupported')) {
      return unsupportedMedia;
    }
    if (lower.contains('timeout') || lower.contains('timed out')) {
      return timeout;
    }
    if (lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('connection')) {
      return networkFailure;
    }
    if (lower.contains('malformed') || lower.contains('invalid json')) {
      return malformedResponse;
    }
    if (lower.contains('persist') || lower.contains('save')) {
      return persistenceFailure;
    }
    if (lower.contains('empty text') || lower.contains('empty transcript')) {
      return emptyTranscript;
    }
    if (lower.contains('transcription failed') ||
        lower.contains('provider') ||
        lower.contains('openai') ||
        lower.contains('proxy')) {
      return providerFailure;
    }
    return unknown;
  }
}

/// Convenience helpers for job transitions.
abstract final class StoryTranscriptionJobTransitions {
  static StoryTranscriptionJob start({
    required StoryId storyId,
    required StoryRepresentationId sourceRepresentationId,
    required String requestId,
    required DateTime at,
    StoryTranscriptionJob? previous,
  }) {
    return StoryTranscriptionJob(
      storyId: storyId,
      sourceRepresentationId: sourceRepresentationId,
      status: StoryTranscriptionJobStatus.inProgress,
      requestId: requestId,
      startedAt: at,
      updatedAt: at,
      attempt: (previous?.attempt ?? 0) + 1,
      transcriptRepresentationId: previous?.transcriptRepresentationId,
    );
  }

  static StoryTranscriptionJob complete({
    required StoryTranscriptionJob job,
    required StoryRepresentationId transcriptRepresentationId,
    required DateTime at,
  }) {
    return job.copyWith(
      status: StoryTranscriptionJobStatus.completed,
      transcriptRepresentationId: transcriptRepresentationId,
      completedAt: at,
      updatedAt: at,
      clearError: true,
    );
  }

  static StoryTranscriptionJob fail({
    required StoryTranscriptionJob job,
    required String errorMessage,
    required String failureKind,
    required DateTime at,
  }) {
    return job.copyWith(
      status: StoryTranscriptionJobStatus.failed,
      errorMessage: errorMessage,
      failureKind: failureKind,
      completedAt: at,
      updatedAt: at,
    );
  }
}

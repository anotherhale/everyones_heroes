import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/start_owned_story_transcription_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/transcribe_story_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/start_owned_story_transcription_response.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/transcribe_story_response.dart';
import 'package:everyonesheroes/features/hero_story/application/transcription/story_transcription_job_store.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/transcribe_story_representation_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/entities/story_representation.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/representation_origin.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_representation_format.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_transcription_job_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';

/// Owner orchestration for explicit Story Detail transcription (HS.11).
///
/// Reuses [TranscribeStoryRepresentationUseCase] / [StoryTranscriptionPort].
/// Does not mutate Story narrative or replace the original recording.
///
/// Retry decision (HS.11): a failed job is reused in-place with a new
/// [requestId] and incremented attempt. Concurrent starts while
/// [StoryTranscriptionJobStatus.inProgress] are rejected. Successful
/// completions are not re-run (caller should review the existing transcript).
final class StartOwnedStoryTranscriptionUseCase
    implements
        UseCase<
          StartOwnedStoryTranscriptionRequest,
          StartOwnedStoryTranscriptionResponse
        > {
  const StartOwnedStoryTranscriptionUseCase({
    required this._storyRepository,
    required this._heroRepository,
    required this._transcribeStory,
    required this._jobStore,
  });

  final StoryRepository _storyRepository;
  final HeroRepository _heroRepository;
  final TranscribeStoryRepresentationUseCase _transcribeStory;
  final StoryTranscriptionJobStore _jobStore;

  @override
  Future<Result<StartOwnedStoryTranscriptionResponse>> execute(
    StartOwnedStoryTranscriptionRequest request,
  ) async {
    final at = request.occurredAt ?? DateTime.now();

    try {
      final hero = await _heroRepository.findById(request.ownerHeroId);
      if (hero == null) {
        return Failure('Hero not found: ${request.ownerHeroId.value}');
      }

      final story = await _storyRepository.findById(request.storyId);
      if (story == null) {
        return Failure('Story not found: ${request.storyId.value}');
      }

      if (story.heroId != request.ownerHeroId) {
        return Failure(
          'Story is not owned by hero: ${request.storyId.value}',
        );
      }

      final source = _resolveSourceRepresentation(
        story,
        request.sourceRepresentationId,
      );
      if (source == null) {
        return const Failure(
          'Original recording is unavailable for transcription.',
        );
      }
      if (source.mediaReference == null) {
        return const Failure(
          'Source representation has no media reference to transcribe.',
        );
      }

      if (!story.consent.isProcessingApproved ||
          !story.consent.isAiTransformationApproved) {
        return const Failure(
          'AI transcription requires processing and AI transformation consent.',
        );
      }

      final existingJob = _jobStore.find(
        storyId: story.id,
        sourceRepresentationId: source.id,
      );

      if (existingJob?.status == StoryTranscriptionJobStatus.inProgress) {
        return Failure(
          'Transcription already in progress for story ${story.id.value}.',
        );
      }

      if (existingJob?.status == StoryTranscriptionJobStatus.completed &&
          !request.isRetry) {
        final transcriptId = existingJob!.transcriptRepresentationId;
        final transcript = transcriptId == null
            ? null
            : story.findRepresentation(transcriptId);
        return Success(
          StartOwnedStoryTranscriptionResponse(
            storyId: story.id,
            sourceRepresentationId: source.id,
            status: StoryTranscriptionJobStatus.completed,
            requestId: existingJob.requestId,
            transcriptRepresentationId: transcriptId,
            transcriptText: transcript?.textContent,
            idempotentReplay: true,
          ),
        );
      }

      if (existingJob?.status == StoryTranscriptionJobStatus.failed &&
          !request.isRetry) {
        return Failure(
          existingJob!.errorMessage ??
              'Previous transcription failed. Retry to try again.',
        );
      }

      // Prefer an existing derived transcript for this source (restart safety).
      final existingTranscript = _existingTranscriptForSource(story, source.id);
      if (existingTranscript != null &&
          existingJob?.status != StoryTranscriptionJobStatus.failed) {
        final completed = StoryTranscriptionJobTransitions.complete(
          job: existingJob ??
              StoryTranscriptionJobTransitions.start(
                storyId: story.id,
                sourceRepresentationId: source.id,
                requestId: request.requestId?.trim().isNotEmpty == true
                    ? request.requestId!.trim()
                    : 'derived-${existingTranscript.id.value}',
                at: at,
              ),
          transcriptRepresentationId: existingTranscript.id,
          at: at,
        );
        _jobStore.save(completed);
        return Success(
          StartOwnedStoryTranscriptionResponse(
            storyId: story.id,
            sourceRepresentationId: source.id,
            status: StoryTranscriptionJobStatus.completed,
            requestId: completed.requestId,
            transcriptRepresentationId: existingTranscript.id,
            transcriptText: existingTranscript.textContent,
            idempotentReplay: true,
          ),
        );
      }

      final requestId = (request.requestId?.trim().isNotEmpty == true)
          ? request.requestId!.trim()
          : 'tx-${story.id.value}-${at.microsecondsSinceEpoch}';

      final transcriptRepresentationId = request.transcriptRepresentationId ??
          existingJob?.transcriptRepresentationId ??
          StoryRepresentationId.generate();

      // If a prior failed attempt already created a representation id that was
      // never saved, reuse it; if it exists on the Story, allocate a fresh id.
      final transcriptId =
          story.findRepresentation(transcriptRepresentationId) != null
              ? StoryRepresentationId.generate()
              : transcriptRepresentationId;

      final started = StoryTranscriptionJobTransitions.start(
        storyId: story.id,
        sourceRepresentationId: source.id,
        requestId: requestId,
        at: at,
        previous: existingJob,
      ).copyWith(transcriptRepresentationId: transcriptId);
      _jobStore.save(started);

      final result = await _transcribeStory.execute(
        TranscribeStoryRequest(
          storyId: story.id,
          sourceRepresentationId: source.id,
          requestId: requestId,
          transcriptRepresentationId: transcriptId,
          processingVersion: request.processingVersion,
          occurredAt: at,
        ),
      );

      if (result is Failure<TranscribeStoryResponse>) {
        final kind = TranscriptionFailureKind.fromMessage(result.error);
        final failed = StoryTranscriptionJobTransitions.fail(
          job: started,
          errorMessage: result.error,
          failureKind: kind,
          at: DateTime.now(),
        );
        _jobStore.save(failed);
        return Failure(result.error);
      }

      final response = (result as Success<TranscribeStoryResponse>).value;
      final completed = StoryTranscriptionJobTransitions.complete(
        job: started,
        transcriptRepresentationId: response.transcriptRepresentationId,
        at: DateTime.now(),
      );
      _jobStore.save(completed);

      final refreshed = await _storyRepository.findById(story.id);
      final transcript = refreshed?.findRepresentation(
        response.transcriptRepresentationId,
      );

      return Success(
        StartOwnedStoryTranscriptionResponse(
          storyId: story.id,
          sourceRepresentationId: source.id,
          status: StoryTranscriptionJobStatus.completed,
          requestId: requestId,
          transcriptRepresentationId: response.transcriptRepresentationId,
          transcriptText: transcript?.textContent,
          idempotentReplay: response.idempotentReplay,
        ),
      );
    } catch (e) {
      return Failure('Failed to start owned story transcription: $e');
    }
  }

  StoryRepresentation? _resolveSourceRepresentation(
    Story story,
    StoryRepresentationId? requested,
  ) {
    if (requested != null) {
      return story.findRepresentation(requested);
    }
    for (final representation in story.representations) {
      if (representation.origin == RepresentationOrigin.original &&
          representation.format == StoryRepresentationFormat.audio) {
        return representation;
      }
    }
    for (final representation in story.representations) {
      if (representation.format == StoryRepresentationFormat.audio) {
        return representation;
      }
    }
    return null;
  }

  StoryRepresentation? _existingTranscriptForSource(
    Story story,
    StoryRepresentationId sourceId,
  ) {
    for (final representation in story.representations) {
      if (representation.format == StoryRepresentationFormat.transcript &&
          representation.sourceRepresentationId == sourceId) {
        return representation;
      }
    }
    return null;
  }
}

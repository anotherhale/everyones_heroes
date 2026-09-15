import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/get_owned_story_transcription_status_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/owned_story_transcription_status.dart';
import 'package:everyonesheroes/features/hero_story/application/transcription/story_transcription_job_store.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/entities/story_representation.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/representation_origin.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_representation_format.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_transcription_job_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';

/// Loads durable transcription job status for Owned Story Detail (HS.11).
final class GetOwnedStoryTranscriptionStatusUseCase
    implements
        UseCase<
          GetOwnedStoryTranscriptionStatusRequest,
          OwnedStoryTranscriptionStatus
        > {
  const GetOwnedStoryTranscriptionStatusUseCase({
    required this._storyRepository,
    required this._heroRepository,
    required this._jobStore,
  });

  final StoryRepository _storyRepository;
  final HeroRepository _heroRepository;
  final StoryTranscriptionJobStore _jobStore;

  @override
  Future<Result<OwnedStoryTranscriptionStatus>> execute(
    GetOwnedStoryTranscriptionStatusRequest request,
  ) async {
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

      final source = _resolveSource(story, request.sourceRepresentationId);
      final hasConsent = story.consent.isProcessingApproved &&
          story.consent.isAiTransformationApproved;

      final job = source == null
          ? null
          : _jobStore.find(
              storyId: story.id,
              sourceRepresentationId: source.id,
            );

      final transcript = source == null
          ? _firstTranscript(story)
          : _transcriptForSource(story, source.id) ??
              (job?.transcriptRepresentationId == null
                  ? null
                  : story.findRepresentation(job!.transcriptRepresentationId!));

      var status = job?.status ?? StoryTranscriptionJobStatus.notStarted;
      if (transcript != null &&
          status != StoryTranscriptionJobStatus.inProgress) {
        status = StoryTranscriptionJobStatus.completed;
      }

      final canStart = source != null &&
          hasConsent &&
          status == StoryTranscriptionJobStatus.notStarted;
      final canRetry = source != null &&
          hasConsent &&
          status == StoryTranscriptionJobStatus.failed;

      return Success(
        OwnedStoryTranscriptionStatus(
          storyId: story.id,
          status: status,
          sourceRepresentationId: source?.id,
          transcriptRepresentationId: transcript?.id ??
              job?.transcriptRepresentationId,
          transcriptText: transcript?.textContent,
          transcriptIsAiGenerated: transcript?.isAiGenerated ?? false,
          transcriptIsApproved: transcript?.isApproved ?? false,
          hasAiProcessingConsent: hasConsent,
          canStart: canStart,
          canRetry: canRetry,
          errorMessage: job?.errorMessage,
          failureKind: job?.failureKind,
          requestId: job?.requestId,
        ),
      );
    } catch (e) {
      return Failure('Failed to get owned story transcription status: $e');
    }
  }

  StoryRepresentation? _resolveSource(
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

  StoryRepresentation? _transcriptForSource(
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

  StoryRepresentation? _firstTranscript(Story story) {
    for (final representation in story.representations) {
      if (representation.format == StoryRepresentationFormat.transcript) {
        return representation;
      }
    }
    return null;
  }
}

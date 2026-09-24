import 'package:everyonesheroes/core/ids/captured_story_reading_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/generate_captured_story_reading_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/generate_captured_story_reading_response.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/captured_story_reading_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/captured_story_reading_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/captured_story_reading.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/grounded_story_element.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/source_span_reference.dart';

/// Generates a grounded captured-story reading from an existing transcript.
///
/// Does not mutate the canonical Story. Requires processing + AI transformation
/// consent. Persists the reading outside the Story aggregate.
final class GenerateCapturedStoryReadingUseCase
    implements
        UseCase<
          GenerateCapturedStoryReadingAppRequest,
          GenerateCapturedStoryReadingResponse
        > {
  const GenerateCapturedStoryReadingUseCase({
    required StoryRepository storyRepository,
    required HeroRepository heroRepository,
    required CapturedStoryReadingPort readingPort,
    required CapturedStoryReadingRepository readingRepository,
  })  : _storyRepository = storyRepository,
        _heroRepository = heroRepository,
        _readingPort = readingPort,
        _readingRepository = readingRepository;

  final StoryRepository _storyRepository;
  final HeroRepository _heroRepository;
  final CapturedStoryReadingPort _readingPort;
  final CapturedStoryReadingRepository _readingRepository;

  @override
  Future<Result<GenerateCapturedStoryReadingResponse>> execute(
    GenerateCapturedStoryReadingAppRequest request,
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

      if (!story.consent.isProcessingApproved ||
          !story.consent.isAiTransformationApproved) {
        return const Failure(
          'Captured story reading requires processing and AI transformation '
          'consent.',
        );
      }

      final transcriptText = request.transcriptText.trim();
      if (transcriptText.isEmpty) {
        return const Failure(
          'Transcript text is required to generate a captured-story reading.',
        );
      }

      final existing = await _readingRepository.findByStoryId(story.id);
      if (existing != null &&
          existing.transcriptRepresentationId ==
              request.transcriptRepresentationId &&
          !request.forceRegenerate) {
        return Success(
          GenerateCapturedStoryReadingResponse(
            reading: existing,
            idempotentReplay: true,
          ),
        );
      }

      final transcript = story.findRepresentation(
        request.transcriptRepresentationId,
      );
      final language = transcript?.language ?? LanguageCode('en');

      final CapturedStoryReadingDraft draft;
      try {
        draft = await _readingPort.generate(
          GenerateCapturedStoryReadingRequest(
            storyId: story.id,
            transcriptRepresentationId: request.transcriptRepresentationId,
            transcriptText: transcriptText,
            language: language,
            processingVersion: request.processingVersion,
          ),
        );
      } on CapturedStoryReadingException catch (e) {
        return Failure(e.message);
      }

      final reading = _mapDraft(
        draft: draft,
        storyId: story.id,
        transcriptRepresentationId: request.transcriptRepresentationId,
        transcriptText: transcriptText,
        at: at,
        processingVersion: request.processingVersion,
      );

      await _readingRepository.save(reading);

      return Success(
        GenerateCapturedStoryReadingResponse(reading: reading),
      );
    } catch (e) {
      return Failure('Failed to generate captured-story reading: $e');
    }
  }

  CapturedStoryReading _mapDraft({
    required CapturedStoryReadingDraft draft,
    required StoryId storyId,
    required StoryRepresentationId transcriptRepresentationId,
    required String transcriptText,
    required DateTime at,
    required String processingVersion,
  }) {
    SourceSpanReference span({
      required int start,
      required int end,
      int? startTs,
      int? endTs,
    }) {
      return SourceSpanReference(
        representationId: transcriptRepresentationId,
        startOffset: start,
        endOffset: end,
        startTimestampMs: startTs,
        endTimestampMs: endTs,
      );
    }

    GroundedStoryElement element(CapturedStoryReadingDraftElement e) {
      return GroundedStoryElement(
        text: e.text,
        sourceSpan: span(
          start: e.startOffset,
          end: e.endOffset,
          startTs: e.startTimestampMs,
          endTs: e.endTimestampMs,
        ),
      );
    }

    final reading = CapturedStoryReading(
      id: CapturedStoryReadingId.generate(),
      storyId: storyId,
      transcriptRepresentationId: transcriptRepresentationId,
      movement: element(draft.movement),
      themes: [
        for (final theme in draft.themes)
          GroundedStoryTheme(
            label: theme.label,
            sourceSpan: span(
              start: theme.startOffset,
              end: theme.endOffset,
            ),
          ),
      ],
      challenge: element(draft.challenge),
      turningPoint: element(draft.turningPoint),
      outcome: element(draft.outcome),
      createdAt: at,
      providerLabel: draft.providerLabel,
      processingVersion:
          draft.processingVersion?.trim().isNotEmpty == true
              ? draft.processingVersion!.trim()
              : processingVersion,
    );

    reading.assertSpansWithinTranscript(transcriptText);
    return reading;
  }
}

import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/generate_captured_story_reading_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/start_owned_story_transcription_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/understand_owned_hero_story_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/generate_captured_story_reading_response.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/start_owned_story_transcription_response.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/understand_owned_hero_story_response.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/generate_captured_story_reading_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/start_owned_story_transcription_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_transcription_job_status.dart';

/// Explicit Hero action: transcribe original recording, then read structure.
///
/// HS-ADR-069: never auto-starts. Leaves the canonical Story unchanged.
/// On failure the original recording remains available for playback.
final class UnderstandOwnedHeroStoryUseCase
    implements
        UseCase<UnderstandOwnedHeroStoryRequest, UnderstandOwnedHeroStoryResponse> {
  const UnderstandOwnedHeroStoryUseCase({
    required StartOwnedStoryTranscriptionUseCase startTranscription,
    required GenerateCapturedStoryReadingUseCase generateReading,
  })  : _startTranscription = startTranscription,
        _generateReading = generateReading;

  final StartOwnedStoryTranscriptionUseCase _startTranscription;
  final GenerateCapturedStoryReadingUseCase _generateReading;

  @override
  Future<Result<UnderstandOwnedHeroStoryResponse>> execute(
    UnderstandOwnedHeroStoryRequest request,
  ) async {
    final transcriptionResult = await _startTranscription.execute(
      StartOwnedStoryTranscriptionRequest(
        storyId: request.storyId,
        ownerHeroId: request.ownerHeroId,
        isRetry: request.isRetry,
        processingVersion: request.processingVersion,
        occurredAt: request.occurredAt,
      ),
    );

    if (transcriptionResult is Failure<StartOwnedStoryTranscriptionResponse>) {
      return Failure(transcriptionResult.error);
    }

    final transcription =
        (transcriptionResult as Success<StartOwnedStoryTranscriptionResponse>)
            .value;

    if (transcription.status != StoryTranscriptionJobStatus.completed) {
      return Failure(
        transcription.errorMessage ??
            'Transcription did not complete successfully.',
      );
    }

    final transcriptId = transcription.transcriptRepresentationId;
    final transcriptText = transcription.transcriptText?.trim() ?? '';
    if (transcriptId == null || transcriptText.isEmpty) {
      return const Failure(
        'Transcription completed without usable transcript text.',
      );
    }

    final readingResult = await _generateReading.execute(
      GenerateCapturedStoryReadingAppRequest(
        storyId: request.storyId,
        ownerHeroId: request.ownerHeroId,
        transcriptRepresentationId: transcriptId,
        transcriptText: transcriptText,
        processingVersion: request.processingVersion,
        occurredAt: request.occurredAt,
        forceRegenerate: request.isRetry,
      ),
    );

    if (readingResult is Failure<GenerateCapturedStoryReadingResponse>) {
      return Failure(readingResult.error);
    }

    final reading =
        (readingResult as Success<GenerateCapturedStoryReadingResponse>).value;

    return Success(
      UnderstandOwnedHeroStoryResponse(
        storyId: request.storyId,
        transcriptRepresentationId: transcriptId,
        transcriptText: transcriptText,
        reading: reading.reading,
        transcriptionIdempotentReplay: transcription.idempotentReplay,
        readingIdempotentReplay: reading.idempotentReplay,
      ),
    );
  }
}

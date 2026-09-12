import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/transcribe_story_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/transcribe_story_response.dart';
import 'package:everyonesheroes/features/hero_story/application/understanding/transcription_completion_store.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/entities/story_representation.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/representation_origin.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_representation_format.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_transformation_type.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_media_storage_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_transcription_port.dart';

/// Transcribes a source representation into a derived AI transcript representation.
///
/// Requires processing + AI consent. Never mutates Story narrative/classification.
final class TranscribeStoryRepresentationUseCase
    implements UseCase<TranscribeStoryRequest, TranscribeStoryResponse> {
  TranscribeStoryRepresentationUseCase({
    required this._storyRepository,
    required this._mediaStorage,
    required this._transcriptionPort,
    required this._eventBus,
    TranscriptionCompletionStore? completionStore,
  }) : _completionStore =
            completionStore ?? InMemoryTranscriptionCompletionStore();

  final StoryRepository _storyRepository;
  final StoryMediaStoragePort _mediaStorage;
  final StoryTranscriptionPort _transcriptionPort;
  final EventBus _eventBus;
  final TranscriptionCompletionStore _completionStore;

  @override
  Future<Result<TranscribeStoryResponse>> execute(
    TranscribeStoryRequest request,
  ) async {
    try {
      final requestId = request.requestId.trim();
      if (requestId.isEmpty) {
        return const Failure('Transcription requestId is required.');
      }

      final existing = _completionStore.find(requestId);
      if (existing != null) {
        return Success(
          TranscribeStoryResponse(
            story: existing.story,
            storyId: existing.storyId,
            transcriptRepresentationId: existing.transcriptRepresentationId,
            mediaReference: existing.mediaReference,
            idempotentReplay: true,
          ),
        );
      }

      final story = await _storyRepository.findById(request.storyId);
      if (story == null) {
        return Failure('Story not found: ${request.storyId.value}');
      }

      if (!story.consent.isProcessingApproved ||
          !story.consent.isAiTransformationApproved) {
        return const Failure(
          'AI transcription requires processing and AI transformation consent.',
        );
      }

      final source = story.findRepresentation(request.sourceRepresentationId);
      if (source == null) {
        return Failure(
          'Source representation not found: '
          '${request.sourceRepresentationId.value}',
        );
      }

      final mediaRef = source.mediaReference;
      if (mediaRef == null) {
        return const Failure(
          'Source representation has no media reference to transcribe.',
        );
      }

      final bytes = await _mediaStorage.retrieve(mediaRef);
      if (bytes == null || bytes.isEmpty) {
        return const Failure('Captured media bytes are missing or empty.');
      }

      if (story.findRepresentation(request.transcriptRepresentationId) !=
          null) {
        return Failure(
          'Transcript representation '
          '${request.transcriptRepresentationId.value} already exists.',
        );
      }

      final transcription = await _transcriptionPort.transcribe(
        TranscribeStoryMediaRequest(
          storyId: story.id,
          sourceRepresentationId: source.id,
          mediaReference: mediaRef,
          language: source.language,
          processingVersion: request.processingVersion,
          requestId: requestId,
          mediaBytes: bytes,
        ),
      );

      if (transcription.text.trim().isEmpty) {
        return const Failure('Transcription produced empty text.');
      }

      final at = request.occurredAt ?? DateTime.now();
      final transcript = StoryRepresentation(
        id: request.transcriptRepresentationId,
        language: transcription.language,
        format: StoryRepresentationFormat.transcript,
        origin: RepresentationOrigin.derived,
        textContent: transcription.text,
        sourceRepresentationId: source.id,
        isAiGenerated: true,
      );

      story.addRepresentation(
        transcript,
        transformationType: StoryTransformationType.transcription,
        at: at,
      );
      await _storyRepository.save(story);

      for (final event in story.pullDomainEvents()) {
        await _eventBus.publish(event);
      }

      final response = TranscribeStoryResponse(
        story: story,
        storyId: story.id,
        transcriptRepresentationId: transcript.id,
        mediaReference: mediaRef,
      );
      _completionStore.save(requestId, response);
      return Success(response);
    } on StoryTranscriptionException catch (e) {
      return Failure('Transcription failed: ${e.message}');
    } catch (e) {
      return Failure('Failed to transcribe story representation: $e');
    }
  }
}

import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/capture/capture_completion_store.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/complete_story_capture_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/complete_story_capture_response.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/entities/story_representation.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/representation_origin.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_representation_format.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_transformation_type.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_media_storage_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';

/// Completes capture by storing media and attaching original audio representation.
///
/// No transcription, AI understanding, classification, or translation (HS.4/HS.5).
final class CompleteStoryCaptureUseCase
    implements
        UseCase<CompleteStoryCaptureRequest, CompleteStoryCaptureResponse> {
  CompleteStoryCaptureUseCase({
    required this._storyRepository,
    required this._heroRepository,
    required this._mediaStorage,
    required this._eventBus,
    CaptureCompletionStore? completionStore,
  }) : _completionStore = completionStore ?? InMemoryCaptureCompletionStore();

  final StoryRepository _storyRepository;
  final HeroRepository _heroRepository;
  final StoryMediaStoragePort _mediaStorage;
  final EventBus _eventBus;
  final CaptureCompletionStore _completionStore;

  @override
  Future<Result<CompleteStoryCaptureResponse>> execute(
    CompleteStoryCaptureRequest request,
  ) async {
    MediaReference? storedReference;
    try {
      final sessionId = request.sessionId.trim();
      if (sessionId.isEmpty) {
        return const Failure('Capture sessionId is required.');
      }

      final existing = _completionStore.find(sessionId);
      if (existing != null) {
        return Success(
          CompleteStoryCaptureResponse(
            story: existing.story,
            storyId: existing.storyId,
            representationId: existing.representationId,
            mediaReference: existing.mediaReference,
            createdStory: existing.createdStory,
            idempotentReplay: true,
          ),
        );
      }

      if (request.mediaBytes.isEmpty) {
        return const Failure('Captured media bytes cannot be empty.');
      }

      final hero = await _heroRepository.findById(request.heroId);
      if (hero == null) {
        return Failure('Hero not found: ${request.heroId.value}');
      }
      if (!hero.isActive) {
        return const Failure('Cannot capture a story for an archived hero.');
      }

      storedReference = await _mediaStorage.store(
        StoreStoryMediaRequest(
          bytes: request.mediaBytes,
          contentType: request.contentType,
          checksum: request.checksum,
          suggestedKey: 'capture/$sessionId',
        ),
      );

      var createdStory = false;
      var story = await _storyRepository.findById(request.storyId);
      if (story == null) {
        story = Story.createFromCapture(
          id: request.storyId,
          heroId: request.heroId,
          originalLanguage: request.originalLanguage,
          title: request.title,
          originalSourceDescription: request.originalSourceDescription,
          createdAt: request.occurredAt,
        );
        createdStory = true;
      } else {
        if (story.heroId != request.heroId) {
          await _mediaStorage.delete(storedReference);
          return const Failure(
            'Story does not belong to the capturing hero.',
          );
        }
        if (story.originalLanguage != request.originalLanguage) {
          await _mediaStorage.delete(storedReference);
          return const Failure(
            'Capture language must match story original language.',
          );
        }
        if (story.findRepresentation(request.representationId) != null) {
          await _mediaStorage.delete(storedReference);
          return Failure(
            'Representation ${request.representationId.value} already exists.',
          );
        }
      }

      final representation = StoryRepresentation(
        id: request.representationId,
        language: request.originalLanguage,
        format: StoryRepresentationFormat.audio,
        origin: RepresentationOrigin.original,
        mediaReference: storedReference,
        duration: request.duration,
        isAiGenerated: false,
        isApproved: false,
      );

      story.addRepresentation(
        representation,
        transformationType: StoryTransformationType.recording,
        at: request.occurredAt,
      );
      story.markCaptureRecorded(at: request.occurredAt);

      await _storyRepository.save(story);

      for (final event in story.pullDomainEvents()) {
        await _eventBus.publish(event);
      }

      final response = CompleteStoryCaptureResponse(
        story: story,
        storyId: story.id,
        representationId: representation.id,
        mediaReference: storedReference,
        createdStory: createdStory,
        idempotentReplay: false,
      );
      _completionStore.save(sessionId, response);
      return Success(response);
    } on StoryMediaStorageException catch (e) {
      return Failure(e.message);
    } catch (e) {
      if (storedReference != null) {
        try {
          await _mediaStorage.delete(storedReference);
        } catch (_) {}
      }
      return Failure('Failed to complete story capture: $e');
    }
  }
}

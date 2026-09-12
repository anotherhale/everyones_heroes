import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/authoring/translation_completion_store.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/translate_story_representation_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/translate_story_representation_response.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/entities/story_representation.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/representation_origin.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_transformation_type.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_translation_port.dart';

/// Translates a source representation into an unapproved target-language copy.
///
/// Slice B (D2). Requires processing + AI consent. Never mutates narrative or
/// Story.originalLanguage.
final class TranslateStoryRepresentationUseCase
    implements
        UseCase<
          TranslateStoryRepresentationRequestDto,
          TranslateStoryRepresentationResponse
        > {
  TranslateStoryRepresentationUseCase({
    required this._storyRepository,
    required this._translationPort,
    required this._eventBus,
    TranslationCompletionStore? completionStore,
  }) : _completionStore =
           completionStore ?? InMemoryTranslationCompletionStore();

  final StoryRepository _storyRepository;
  final StoryTranslationPort _translationPort;
  final EventBus _eventBus;
  final TranslationCompletionStore _completionStore;

  @override
  Future<Result<TranslateStoryRepresentationResponse>> execute(
    TranslateStoryRepresentationRequestDto request,
  ) async {
    try {
      final requestId = request.requestId.trim();
      if (requestId.isEmpty) {
        return const Failure('Translation requestId is required.');
      }

      final existing = _completionStore.find(requestId);
      if (existing != null) {
        return Success(
          TranslateStoryRepresentationResponse(
            story: existing.story,
            storyId: existing.storyId,
            translatedRepresentationId: existing.translatedRepresentationId,
            targetLanguage: existing.targetLanguage,
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
          'AI translation requires processing and AI transformation consent.',
        );
      }

      final source = story.findRepresentation(request.sourceRepresentationId);
      if (source == null) {
        return Failure(
          'Source representation not found: '
          '${request.sourceRepresentationId.value}',
        );
      }

      final sourceText = source.textContent?.trim() ?? '';
      if (sourceText.isEmpty) {
        return const Failure(
          'Source representation has no text content to translate.',
        );
      }

      if (story.findRepresentation(request.translatedRepresentationId) !=
          null) {
        return Failure(
          'Translated representation '
          '${request.translatedRepresentationId.value} already exists.',
        );
      }

      final originalLanguageBefore = story.originalLanguage;
      final narrativeBefore = story.narrative.value;

      final draft = await _translationPort.translate(
        TranslateStoryRepresentationRequest(
          storyId: story.id,
          sourceRepresentationId: source.id,
          sourceText: sourceText,
          sourceLanguage: source.language,
          targetLanguage: request.targetLanguage,
          sourceFormat: source.format,
          processingVersion: request.processingVersion,
          requestId: requestId,
        ),
      );

      if (draft.textContent.trim().isEmpty) {
        return const Failure('Translation produced empty text.');
      }

      final at = request.occurredAt ?? DateTime.now();
      final translated = StoryRepresentation(
        id: request.translatedRepresentationId,
        language: draft.language,
        format: draft.format,
        origin: RepresentationOrigin.translated,
        textContent: draft.textContent,
        sourceRepresentationId: source.id,
        isAiGenerated: true,
      );

      story.addRepresentation(
        translated,
        transformationType: StoryTransformationType.translation,
        at: at,
      );
      await _storyRepository.save(story);

      for (final event in story.pullDomainEvents()) {
        await _eventBus.publish(event);
      }

      if (story.narrative.value != narrativeBefore) {
        return const Failure(
          'Translation must not mutate canonical Story narrative.',
        );
      }
      if (story.originalLanguage != originalLanguageBefore) {
        return const Failure(
          'Translation must not mutate Story.originalLanguage.',
        );
      }

      final response = TranslateStoryRepresentationResponse(
        story: story,
        storyId: story.id,
        translatedRepresentationId: translated.id,
        targetLanguage: translated.language,
      );
      _completionStore.save(requestId, response);
      return Success(response);
    } on StoryTranslationException catch (e) {
      return Failure('Translation failed: ${e.message}');
    } catch (e) {
      return Failure('Failed to translate story representation: $e');
    }
  }
}

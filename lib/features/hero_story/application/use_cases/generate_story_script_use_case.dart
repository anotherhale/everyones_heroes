import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/authoring/authoring_completion_store.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/generate_story_script_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/generate_story_script_response.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/entities/story_representation.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/representation_origin.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_representation_format.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_transformation_type.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_understanding_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_authoring_port.dart';

/// Generates an unapproved authored StoryRepresentation (script/shortForm/…).
///
/// Requires processing + AI consent. Never mutates Story.narrative (D3).
/// Approved StoryUnderstanding is optional context only (D8).
final class GenerateStoryScriptUseCase
    implements
        UseCase<GenerateStoryScriptRequest, GenerateStoryScriptResponse> {
  GenerateStoryScriptUseCase({
    required this._storyRepository,
    required this._authoringPort,
    required this._eventBus,
    StoryUnderstandingRepository? understandingRepository,
    AuthoringCompletionStore? completionStore,
  }) : _understandingRepository = understandingRepository,
       _completionStore =
           completionStore ?? InMemoryAuthoringCompletionStore();

  final StoryRepository _storyRepository;
  final StoryAuthoringPort _authoringPort;
  final EventBus _eventBus;
  final StoryUnderstandingRepository? _understandingRepository;
  final AuthoringCompletionStore _completionStore;

  static const _allowedFormats = {
    StoryRepresentationFormat.script,
    StoryRepresentationFormat.shortForm,
    StoryRepresentationFormat.longForm,
  };

  @override
  Future<Result<GenerateStoryScriptResponse>> execute(
    GenerateStoryScriptRequest request,
  ) async {
    try {
      final requestId = request.requestId.trim();
      if (requestId.isEmpty) {
        return const Failure('Authoring requestId is required.');
      }

      final existing = _completionStore.find(requestId);
      if (existing != null) {
        return Success(
          GenerateStoryScriptResponse(
            story: existing.story,
            storyId: existing.storyId,
            authoredRepresentationId: existing.authoredRepresentationId,
            format: existing.format,
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
          'AI authoring requires processing and AI transformation consent.',
        );
      }

      if (!_allowedFormats.contains(request.targetFormat)) {
        return Failure(
          'Unsupported authoring format: ${request.targetFormat.name}',
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
          'Source representation has no text content to author from.',
        );
      }

      if (story.findRepresentation(request.authoredRepresentationId) != null) {
        return Failure(
          'Authored representation '
          '${request.authoredRepresentationId.value} already exists.',
        );
      }

      String? understandingContext;
      if (request.understandingId != null) {
        final repo = _understandingRepository;
        if (repo == null) {
          return const Failure(
            'StoryUnderstandingRepository is required when understandingId '
            'is provided.',
          );
        }
        final understanding =
            await repo.findById(request.understandingId!);
        if (understanding == null) {
          return Failure(
            'StoryUnderstanding not found: '
            '${request.understandingId!.value}',
          );
        }
        if (understanding.storyId != story.id) {
          return const Failure(
            'StoryUnderstanding does not belong to this Story.',
          );
        }
        if (!understanding.status.isApplicable) {
          return Failure(
            'StoryUnderstanding ${request.understandingId!.value} is not '
            'approved/applicable for authoring context.',
          );
        }
        understandingContext = understanding.observations
            .map((o) => o.content)
            .where((c) => c.trim().isNotEmpty)
            .take(5)
            .join(' | ');
      }

      final draft = await _authoringPort.generate(
        GenerateStoryAuthoringRequest(
          storyId: story.id,
          sourceRepresentationId: source.id,
          sourceText: sourceText,
          language: source.language,
          targetFormat: request.targetFormat,
          processingVersion: request.processingVersion,
          requestId: requestId,
          understandingContext: understandingContext,
        ),
      );

      if (draft.textContent.trim().isEmpty) {
        return const Failure('Authoring produced empty text.');
      }

      final narrativeBefore = story.narrative.value;
      final at = request.occurredAt ?? DateTime.now();
      final representation = StoryRepresentation(
        id: request.authoredRepresentationId,
        language: draft.language,
        format: draft.format,
        origin: RepresentationOrigin.derived,
        textContent: draft.textContent,
        sourceRepresentationId: source.id,
        isAiGenerated: true,
      );

      final transformationType = switch (request.targetFormat) {
        StoryRepresentationFormat.script =>
          StoryTransformationType.scriptGeneration,
        StoryRepresentationFormat.shortForm =>
          StoryTransformationType.summarization,
        StoryRepresentationFormat.longForm =>
          StoryTransformationType.formatConversion,
        _ => StoryTransformationType.other,
      };

      story.addRepresentation(
        representation,
        transformationType: transformationType,
        at: at,
      );
      await _storyRepository.save(story);

      for (final event in story.pullDomainEvents()) {
        await _eventBus.publish(event);
      }

      if (story.narrative.value != narrativeBefore) {
        return const Failure(
          'Authoring must not mutate canonical Story narrative.',
        );
      }

      final response = GenerateStoryScriptResponse(
        story: story,
        storyId: story.id,
        authoredRepresentationId: representation.id,
        format: representation.format,
      );
      _completionStore.save(requestId, response);
      return Success(response);
    } on StoryAuthoringException catch (e) {
      return Failure('Authoring failed: ${e.message}');
    } catch (e) {
      return Failure('Failed to generate authored representation: $e');
    }
  }
}

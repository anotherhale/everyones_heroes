import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/ids/story_understanding_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/generate_story_understanding_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/generate_story_understanding_response.dart';
import 'package:everyonesheroes/features/hero_story/application/understanding/understanding_completion_store.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_understanding.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/observation_kind.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/understanding_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_understanding_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_understanding_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_observation.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/understanding_provenance.dart';

/// Generates a proposed StoryUnderstanding without mutating canonical Story catalog.
final class GenerateStoryUnderstandingUseCase
    implements
        UseCase<
          GenerateStoryUnderstandingRequest,
          GenerateStoryUnderstandingResponse
        > {
  GenerateStoryUnderstandingUseCase({
    required this._storyRepository,
    required this._understandingRepository,
    required this._understandingPort,
    required this._eventBus,
    UnderstandingCompletionStore? completionStore,
  }) : _completionStore =
            completionStore ?? InMemoryUnderstandingCompletionStore();

  final StoryRepository _storyRepository;
  final StoryUnderstandingRepository _understandingRepository;
  final StoryUnderstandingPort _understandingPort;
  final EventBus _eventBus;
  final UnderstandingCompletionStore _completionStore;

  @override
  Future<Result<GenerateStoryUnderstandingResponse>> execute(
    GenerateStoryUnderstandingRequest request,
  ) async {
    try {
      final requestId = request.requestId.trim();
      if (requestId.isEmpty) {
        return const Failure('Understanding requestId is required.');
      }

      final existing = _completionStore.find(requestId);
      if (existing != null) {
        return Success(
          GenerateStoryUnderstandingResponse(
            understanding: existing.understanding,
            understandingId: existing.understandingId,
            storyId: existing.storyId,
            supersededUnderstandingId: existing.supersededUnderstandingId,
            idempotentReplay: true,
          ),
        );
      }

      if (request.sourceRepresentationIds.isEmpty) {
        return const Failure(
          'At least one source representation id is required.',
        );
      }

      final story = await _storyRepository.findById(request.storyId);
      if (story == null) {
        return Failure('Story not found: ${request.storyId.value}');
      }

      if (!story.consent.isProcessingApproved ||
          !story.consent.isAiTransformationApproved) {
        return const Failure(
          'Story understanding requires processing and AI transformation consent.',
        );
      }

      final buffer = StringBuffer();
      for (final repId in request.sourceRepresentationIds) {
        final rep = story.findRepresentation(repId);
        if (rep == null) {
          return Failure('Source representation not found: ${repId.value}');
        }
        final text = rep.textContent?.trim();
        if (text == null || text.isEmpty) {
          return Failure(
            'Source representation ${repId.value} has no text content. '
            'Transcribe audio before understanding, or provide a text source.',
          );
        }
        buffer.writeln(text);
      }

      final sourceText = buffer.toString().trim();
      if (sourceText.isEmpty) {
        return const Failure('Combined source text for understanding is empty.');
      }

      final analysisLanguage =
          story.findRepresentation(request.sourceRepresentationIds.first)!
              .language;

      final draft = await _understandingPort.analyze(
        AnalyzeStoryContentRequest(
          storyId: story.id,
          sourceRepresentationIds: request.sourceRepresentationIds,
          sourceText: sourceText,
          analysisLanguage: analysisLanguage,
          processingVersion: request.processingVersion,
          requestId: requestId,
        ),
      );

      final at = request.occurredAt ?? DateTime.now();
      final observations = List<StoryObservation>.of(draft.observations);
      for (final uncertainty in draft.uncertainties) {
        if (uncertainty.trim().isEmpty) {
          continue;
        }
        observations.add(
          StoryObservation(
            kind: ObservationKind.uncertainty,
            content: uncertainty,
          ),
        );
      }

      final history = await _understandingRepository.findByStoryId(story.id);
      final priorToSupersede = history
          .where((u) => u.status != UnderstandingStatus.superseded)
          .toList();

      final StoryUnderstandingId? supersedesLink =
          priorToSupersede.isEmpty ? null : priorToSupersede.last.id;

      final provenance = UnderstandingProvenance(
        sourceRepresentationIds: request.sourceRepresentationIds,
        analyzedAt: at,
        providerLabel: draft.providerLabel ?? 'unknown',
        modelLabel: draft.modelLabel,
        promptOrTemplateVersion: draft.promptOrTemplateVersion,
        processingVersion: request.processingVersion,
        supportLevel: draft.supportLevel,
        opaqueProviderConfidence: draft.opaqueProviderConfidence,
      );

      final understanding = StoryUnderstanding.createProposed(
        id: request.understandingId,
        storyId: story.id,
        sourceRepresentationIds: request.sourceRepresentationIds,
        analysisLanguage: analysisLanguage,
        detectedLanguage: draft.detectedLanguage,
        candidateClassification: draft.candidateClassification,
        candidateContentSuitability: draft.candidateSuitability,
        candidateSpirituality: draft.candidateSpirituality,
        observations: observations,
        provenance: provenance,
        processingVersion: request.processingVersion,
        supersedesUnderstandingId: supersedesLink,
        createdAt: at,
      );

      await _understandingRepository.save(understanding);

      StoryUnderstandingId? actuallySuperseded;
      for (final prior in priorToSupersede) {
        prior.markSupersededBy(understanding.id);
        await _understandingRepository.save(prior);
        actuallySuperseded = prior.id;
        for (final event in prior.pullDomainEvents()) {
          await _eventBus.publish(event);
        }
      }

      for (final event in understanding.pullDomainEvents()) {
        await _eventBus.publish(event);
      }

      final response = GenerateStoryUnderstandingResponse(
        understanding: understanding,
        understandingId: understanding.id,
        storyId: story.id,
        supersededUnderstandingId: actuallySuperseded,
      );
      _completionStore.save(requestId, response);
      return Success(response);
    } on StoryUnderstandingException catch (e) {
      return Failure('Understanding generation failed: ${e.message}');
    } catch (e) {
      return Failure('Failed to generate story understanding: $e');
    }
  }
}

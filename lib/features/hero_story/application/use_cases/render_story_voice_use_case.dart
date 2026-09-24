import 'package:everyonesheroes/core/ids/story_voice_rendering_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/render_story_voice_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/render_story_voice_response.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/voice_rendering_mode.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_experience_plan_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_voice_rendering_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_media_storage_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/voice_rendering_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_voice_rendering.dart';

/// Renders and persists a derived AI voice presentation (HS.12.6).
///
/// Requires explicit [StoryConsent.isVoiceRenderingApproved]. Recording,
/// processing, transcription, publication, or AI-transformation consent alone
/// is insufficient.
///
/// Does not mutate the canonical Story, CapturedStoryReading, or
/// StoryExperiencePlan. Does not create behavioral evidence.
final class RenderStoryVoiceUseCase
    implements UseCase<RenderStoryVoiceAppRequest, RenderStoryVoiceResponse> {
  const RenderStoryVoiceUseCase({
    required StoryRepository storyRepository,
    required HeroRepository heroRepository,
    required StoryExperiencePlanRepository planRepository,
    required VoiceRenderingPort voiceRenderingPort,
    required StoryVoiceRenderingRepository renderingRepository,
    required StoryMediaStoragePort mediaStorage,
  })  : _storyRepository = storyRepository,
        _heroRepository = heroRepository,
        _planRepository = planRepository,
        _voiceRenderingPort = voiceRenderingPort,
        _renderingRepository = renderingRepository,
        _mediaStorage = mediaStorage;

  final StoryRepository _storyRepository;
  final HeroRepository _heroRepository;
  final StoryExperiencePlanRepository _planRepository;
  final VoiceRenderingPort _voiceRenderingPort;
  final StoryVoiceRenderingRepository _renderingRepository;
  final StoryMediaStoragePort _mediaStorage;

  static const Set<String> _acceptedContentTypes = {
    'audio/mpeg',
    'audio/mp3',
    'audio/mp4',
    'audio/m4a',
    'audio/wav',
    'audio/x-wav',
    'audio/ogg',
    'audio/opus',
  };

  @override
  Future<Result<RenderStoryVoiceResponse>> execute(
    RenderStoryVoiceAppRequest request,
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

      if (!story.consent.isVoiceRenderingApproved) {
        return const Failure(
          'AI voice rendering requires explicit voice-rendering authorization. '
          'Recording, transcription, processing, or AI transformation consent '
          'alone is not sufficient.',
        );
      }

      if (request.renderingMode != VoiceRenderingMode.syntheticNarration) {
        return Failure(
          'Voice rendering mode "${request.renderingMode.name}" is not '
          'supported in HS.12.6. Only syntheticNarration is available.',
        );
      }

      final plan = await _planRepository.findByStoryId(story.id);
      if (plan == null) {
        return Failure(
          'StoryExperiencePlan not found for story: ${story.id.value}. '
          'Create my experience before rendering a narrated version.',
        );
      }

      if (!request.forceRegenerate) {
        final existing = await _renderingRepository.findByStoryId(story.id);
        if (existing != null &&
            existing.experiencePlanId == plan.id &&
            existing.experiencePlanProcessingVersion ==
                plan.processingVersion &&
            existing.renderingMode == request.renderingMode) {
          return Success(
            RenderStoryVoiceResponse(
              rendering: existing,
              idempotentReplay: true,
            ),
          );
        }
      }

      final transcript = story.findRepresentation(
        plan.transcriptRepresentationId,
      );
      final sourceText = transcript?.textContent?.trim() ?? '';
      if (sourceText.isEmpty) {
        return const Failure(
          'Transcript text is required to render a narrated version.',
        );
      }

      final VoiceRenderingDraft draft;
      try {
        draft = await _voiceRenderingPort.render(
          VoiceRenderingRequest(
            storyId: story.id,
            experiencePlanId: plan.id,
            experiencePlanProcessingVersion: plan.processingVersion,
            sourceRepresentationId: plan.transcriptRepresentationId,
            sourceText: sourceText,
            renderingMode: request.renderingMode,
            processingVersion: request.processingVersion,
          ),
        );
      } on VoiceRenderingException catch (e) {
        return Failure(e.message);
      }

      final validationError = _validateDraft(draft);
      if (validationError != null) {
        return Failure(validationError);
      }

      final renderingId = StoryVoiceRenderingId.generate();
      final mediaReference = await _mediaStorage.store(
        StoreStoryMediaRequest(
          bytes: draft.audioBytes,
          contentType: draft.contentType.trim(),
          suggestedKey: 'voice_rendering_${story.id.value}_${renderingId.value}',
        ),
      );

      final rendering = StoryVoiceRendering(
        id: renderingId,
        storyId: story.id,
        experiencePlanId: plan.id,
        experiencePlanProcessingVersion: plan.processingVersion,
        sourceRepresentationId: plan.transcriptRepresentationId,
        renderingMode: draft.renderingMode,
        mediaReference: mediaReference,
        contentType: draft.contentType.trim(),
        byteLength: draft.audioBytes.length,
        createdAt: at,
        providerLabel: draft.providerLabel,
        modelLabel: draft.modelLabel,
        processingVersion:
            draft.processingVersion?.trim().isNotEmpty == true
                ? draft.processingVersion!.trim()
                : request.processingVersion,
      );

      await _renderingRepository.save(rendering);

      return Success(RenderStoryVoiceResponse(rendering: rendering));
    } on StoryMediaStorageException catch (e) {
      return Failure('Failed to persist generated voice audio: ${e.message}');
    } catch (e) {
      return Failure('Failed to render story voice: $e');
    }
  }

  static String? _validateDraft(VoiceRenderingDraft draft) {
    if (draft.audioBytes.isEmpty) {
      return 'Generated voice audio is empty.';
    }
    final contentType = draft.contentType.trim().toLowerCase();
    if (contentType.isEmpty) {
      return 'Generated voice response is missing content type.';
    }
    final baseType = contentType.split(';').first.trim();
    if (!_acceptedContentTypes.contains(baseType)) {
      return 'Unexpected generated voice content type: $contentType';
    }
    if (draft.renderingMode != VoiceRenderingMode.syntheticNarration) {
      return 'Unsupported voice rendering mode in provider response: '
          '${draft.renderingMode.name}';
    }
    return null;
  }
}

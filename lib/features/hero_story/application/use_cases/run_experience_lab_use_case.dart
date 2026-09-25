import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'package:everyonesheroes/core/ids/experience_lab_run_id.dart';
import 'package:everyonesheroes/core/ids/music_rendering_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_voice_rendering_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/run_experience_lab_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/run_experience_lab_response.dart';
import 'package:everyonesheroes/features/hero_story/application/lab/experience_music_prompt_builder.dart';
import 'package:everyonesheroes/features/hero_story/application/lab/experience_render_manifest.dart';
import 'package:everyonesheroes/features/hero_story/application/lab/experience_render_manifest_builder.dart';
import 'package:everyonesheroes/features/hero_story/application/lab/presentation_creative_direction.dart';
import 'package:everyonesheroes/features/hero_story/application/playback/story_experience_timeline.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/experience_lab_run_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/voice_rendering_mode.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/experience_lab_run_repository.dart';
import 'package:everyonesheroes/features/hero_story/application/lab/experience_render_manifest_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/music_rendering_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_experience_plan_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_voice_rendering_repository.dart';
import 'package:everyonesheroes/features/hero_story/application/lab/creative_direction_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/music_generation_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_media_storage_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/voice_rendering_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/experience_lab_provider_config.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/experience_lab_run.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/music_rendering.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_plan.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_voice_rendering.dart';

/// Orchestrates Experiment A laboratory generation.
///
/// Pipeline: existing StoryExperiencePlan → creative direction → TTS →
/// Stable Audio music bed → ExperienceRenderManifest → ExperienceLabRun.
///
/// Does not mutate Story, CapturedStoryReading, or StoryExperiencePlan.
/// Does not call AI on playback — artifacts are persisted for reuse.
final class RunExperienceLabUseCase
    implements UseCase<RunExperienceLabRequest, RunExperienceLabResponse> {
  const RunExperienceLabUseCase({
    required StoryRepository storyRepository,
    required HeroRepository heroRepository,
    required StoryExperiencePlanRepository planRepository,
    required CreativeDirectionPort creativeDirectionPort,
    required VoiceRenderingPort voiceRenderingPort,
    required MusicGenerationPort musicGenerationPort,
    required StoryVoiceRenderingRepository voiceRenderingRepository,
    required MusicRenderingRepository musicRenderingRepository,
    required ExperienceLabRunRepository labRunRepository,
    required ExperienceRenderManifestRepository manifestRepository,
    required StoryMediaStoragePort mediaStorage,
    StoryExperienceTimelineBuilder timelineBuilder =
        const StoryExperienceTimelineBuilder(),
    ExperienceRenderManifestBuilder manifestBuilder =
        const ExperienceRenderManifestBuilder(),
  })  : _storyRepository = storyRepository,
        _heroRepository = heroRepository,
        _planRepository = planRepository,
        _creativeDirectionPort = creativeDirectionPort,
        _voiceRenderingPort = voiceRenderingPort,
        _musicGenerationPort = musicGenerationPort,
        _voiceRenderingRepository = voiceRenderingRepository,
        _musicRenderingRepository = musicRenderingRepository,
        _labRunRepository = labRunRepository,
        _manifestRepository = manifestRepository,
        _mediaStorage = mediaStorage,
        _timelineBuilder = timelineBuilder,
        _manifestBuilder = manifestBuilder;

  final StoryRepository _storyRepository;
  final HeroRepository _heroRepository;
  final StoryExperiencePlanRepository _planRepository;
  final CreativeDirectionPort _creativeDirectionPort;
  final VoiceRenderingPort _voiceRenderingPort;
  final MusicGenerationPort _musicGenerationPort;
  final StoryVoiceRenderingRepository _voiceRenderingRepository;
  final MusicRenderingRepository _musicRenderingRepository;
  final ExperienceLabRunRepository _labRunRepository;
  final ExperienceRenderManifestRepository _manifestRepository;
  final StoryMediaStoragePort _mediaStorage;
  final StoryExperienceTimelineBuilder _timelineBuilder;
  final ExperienceRenderManifestBuilder _manifestBuilder;

  static const Set<String> _acceptedAudioTypes = {
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
  Future<Result<RunExperienceLabResponse>> execute(
    RunExperienceLabRequest request,
  ) async {
    final at = request.occurredAt ?? DateTime.now();
    final config = request.config ?? ExperienceLabProviderConfig.experimentA();

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
          'AI experience laboratory requires explicit voice-rendering '
          'authorization for synthetic narration.',
        );
      }
      if (!story.consent.isMusicGenerationApproved) {
        return const Failure(
          'AI experience laboratory requires explicit music-generation '
          'authorization. Recording or AI-transformation consent alone is '
          'not sufficient.',
        );
      }

      final plan = await _planRepository.findByStoryId(story.id);
      if (plan == null) {
        return Failure(
          'StoryExperiencePlan not found for story: ${story.id.value}. '
          'Create my experience before generating an AI lab experience.',
        );
      }

      if (!request.forceRegenerate) {
        final existing = await _labRunRepository.findByStoryId(story.id);
        if (existing != null &&
            existing.isPlayable &&
            existing.experiencePlanId == plan.id &&
            existing.experiencePlanProcessingVersion == plan.processingVersion &&
            existing.config.fingerprint == config.fingerprint) {
          final manifest = existing.renderManifestId == null
              ? null
              : await _manifestRepository.findById(existing.renderManifestId!);
          final music = existing.musicRenderingId == null
              ? null
              : await _musicRenderingRepository
                  .findById(existing.musicRenderingId!);
          final voice = existing.voiceRenderingId == null
              ? null
              : await _voiceRenderingRepository
                  .findById(existing.voiceRenderingId!);
          if (manifest != null && music != null) {
            return Success(
              RunExperienceLabResponse(
                labRun: existing,
                manifest: manifest,
                musicRendering: music,
                voiceRendering: voice,
                idempotentReplay: true,
              ),
            );
          }
        }
      }

      final runId = ExperienceLabRunId.generate();
      var run = ExperienceLabRun(
        id: runId,
        storyId: story.id,
        config: config,
        experiencePlanId: plan.id,
        experiencePlanProcessingVersion: plan.processingVersion,
        status: ExperienceLabRunStatus.generating,
        createdAt: at,
      );
      await _labRunRepository.save(run);

      // 1) Creative direction — fails loudly; no silent repair.
      final PresentationCreativeDirection direction;
      try {
        direction = await _creativeDirectionPort.direct(
          CreativeDirectionRequest(
            storyId: story.id,
            experiencePlanId: plan.id,
            experiencePlanProcessingVersion: plan.processingVersion,
            intention: plan.intention,
            coreMessage: plan.coreMessage,
            emotionalArc: plan.emotionalArc,
            musicDirection: plan.musicDirection,
            keyMomentLabels:
                plan.keyMoments.map((m) => m.description).toList(),
            sequenceStepTypes: plan.sequence.map((s) => s.type.name).toList(),
            reflectionPrompt: plan.reflectionPrompt,
            targetDurationSeconds: request.targetDurationSeconds,
            processingVersion: config.creativePromptVersion,
            providerHint: config.creativeProvider,
            modelHint: config.creativeModel,
          ),
        );
      } on CreativeDirectionException catch (e) {
        run = run.copyWith(
          status: ExperienceLabRunStatus.failed,
          completedAt: DateTime.now(),
          errorSummary: 'Creative direction failed: ${e.message}',
        );
        await _labRunRepository.save(run);
        return Failure(run.errorSummary!);
      }

      run = run.copyWith(
        creativeDirectionDigest:
            '${direction.processingVersion}:${direction.musicPromptBrief.hashCode}',
      );
      await _labRunRepository.save(run);

      // 2) Voice rendering (synthetic narration) — explicit failure.
      StoryVoiceRendering? voiceRendering;
      try {
        voiceRendering = await _renderVoice(
          storyId: story.id,
          plan: plan,
          at: at,
          forceRegenerate: request.forceRegenerate,
        );
        run = run.copyWith(voiceRenderingId: voiceRendering.id);
        await _labRunRepository.save(run);
      } catch (e) {
        run = run.copyWith(
          status: ExperienceLabRunStatus.failed,
          completedAt: DateTime.now(),
          errorSummary: 'TTS narration failed: $e',
        );
        await _labRunRepository.save(run);
        return Failure(run.errorSummary!);
      }

      // 3) Music generation — no silent demo-stem fallback.
      MusicRendering musicRendering;
      try {
        musicRendering = await _renderMusic(
          storyId: story.id,
          plan: plan,
          direction: direction,
          config: config,
          experimentId: runId.value,
          targetDurationSeconds: request.targetDurationSeconds ??
              _defaultDurationSeconds(plan),
          at: at,
        );
        run = run.copyWith(musicRenderingId: musicRendering.id);
        await _labRunRepository.save(run);
      } catch (e) {
        run = run.copyWith(
          status: ExperienceLabRunStatus.partial,
          completedAt: DateTime.now(),
          errorSummary: 'Music generation failed: $e',
        );
        await _labRunRepository.save(run);
        return Failure(run.errorSummary!);
      }

      // 4) Timeline + manifest (reuse existing timeline builder).
      final recordingDuration = Duration(
        seconds: request.targetDurationSeconds ?? _defaultDurationSeconds(plan),
      );
      final timeline = _timelineBuilder.build(
        plan: plan,
        recordingDuration: recordingDuration,
      );
      final manifest = _manifestBuilder.build(
        plan: plan,
        timeline: timeline,
        config: config,
        musicRenderingId: musicRendering.id,
        voiceRenderingId: voiceRendering.id,
        creativeDirection: direction,
        recordingRole: ExperienceRenderRecordingRole.originalPlusNarrationBeds,
        createdAt: at,
      );
      await _manifestRepository.save(manifest);

      run = run.copyWith(
        renderManifestId: manifest.id,
        status: ExperienceLabRunStatus.succeeded,
        completedAt: DateTime.now(),
        clearError: true,
      );
      await _labRunRepository.save(run);

      return Success(
        RunExperienceLabResponse(
          labRun: run,
          manifest: manifest,
          musicRendering: musicRendering,
          voiceRendering: voiceRendering,
        ),
      );
    } on StoryMediaStorageException catch (e) {
      return Failure('Failed to persist lab audio artifact: ${e.message}');
    } catch (e) {
      return Failure('Failed to run experience laboratory: $e');
    }
  }

  Future<StoryVoiceRendering> _renderVoice({
    required StoryId storyId,
    required StoryExperiencePlan plan,
    required DateTime at,
    required bool forceRegenerate,
  }) async {
    if (!forceRegenerate) {
      final existing = await _voiceRenderingRepository.findByStoryId(storyId);
      if (existing != null &&
          existing.experiencePlanId == plan.id &&
          existing.experiencePlanProcessingVersion == plan.processingVersion &&
          existing.renderingMode == VoiceRenderingMode.syntheticNarration) {
        return existing;
      }
    }

    // storyId is StoryId — need the Story for transcript text.
    final story = await _storyRepository.findById(storyId);
    if (story == null) {
      throw StateError('Story disappeared during lab generation.');
    }
    final transcript = story.findRepresentation(plan.transcriptRepresentationId);
    final sourceText = transcript?.textContent?.trim() ?? '';
    if (sourceText.isEmpty) {
      throw const VoiceRenderingException(
        'Transcript text is required to render lab narration.',
      );
    }

    final draft = await _voiceRenderingPort.render(
      VoiceRenderingRequest(
        storyId: story.id,
        experiencePlanId: plan.id,
        experiencePlanProcessingVersion: plan.processingVersion,
        sourceRepresentationId: plan.transcriptRepresentationId,
        sourceText: sourceText,
        renderingMode: VoiceRenderingMode.syntheticNarration,
      ),
    );
    if (draft.audioBytes.isEmpty) {
      throw const VoiceRenderingException('Generated voice audio is empty.');
    }
    final contentType = draft.contentType.trim().toLowerCase();
    final baseType = contentType.split(';').first.trim();
    if (!_acceptedAudioTypes.contains(baseType)) {
      throw VoiceRenderingException(
        'Unexpected voice content type: ${draft.contentType}',
      );
    }

    final renderingId = StoryVoiceRenderingId.generate();
    final mediaReference = await _mediaStorage.store(
      StoreStoryMediaRequest(
        bytes: draft.audioBytes,
        contentType: draft.contentType.trim(),
        suggestedKey: 'lab_voice_${story.id.value}_${renderingId.value}',
      ),
    );

    final rendering = StoryVoiceRendering(
      id: renderingId,
      storyId: story.id,
      experiencePlanId: plan.id,
      experiencePlanProcessingVersion: plan.processingVersion,
      sourceRepresentationId: plan.transcriptRepresentationId,
      renderingMode: VoiceRenderingMode.syntheticNarration,
      mediaReference: mediaReference,
      contentType: draft.contentType.trim(),
      byteLength: draft.audioBytes.length,
      createdAt: at,
      providerLabel: draft.providerLabel,
      modelLabel: draft.modelLabel,
      processingVersion: draft.processingVersion?.trim().isNotEmpty == true
          ? draft.processingVersion!.trim()
          : StoryVoiceRendering.defaultProcessingVersion,
    );
    await _voiceRenderingRepository.save(rendering);
    return rendering;
  }

  Future<MusicRendering> _renderMusic({
    required StoryId storyId,
    required StoryExperiencePlan plan,
    required PresentationCreativeDirection direction,
    required ExperienceLabProviderConfig config,
    required String experimentId,
    required int targetDurationSeconds,
    required DateTime at,
  }) async {
    final prompt = ExperienceMusicPromptBuilder.build(
      plan: plan,
      creativeDirection: direction,
    );
    final draft = await _musicGenerationPort.generate(
      MusicGenerationRequest(
        storyId: storyId,
        experiencePlanId: plan.id,
        experiencePlanProcessingVersion: plan.processingVersion,
        prompt: prompt,
        targetDurationSeconds: targetDurationSeconds.clamp(1, 380),
        mood: plan.musicDirection.mood,
        energy: plan.musicDirection.energy,
        style: plan.musicDirection.style,
        instrumentalPreferred: true,
        intensityCurveHints:
            ExperienceMusicPromptBuilder.intensityHintsFromDirection(direction),
        processingVersion: config.musicPromptVersion,
        providerHint: config.musicProvider,
        modelHint: config.musicModel,
        experimentId: experimentId,
      ),
    );
    if (draft.audioBytes.isEmpty) {
      throw const MusicGenerationException('Generated music audio is empty.');
    }
    if (!draft.instrumental) {
      throw const MusicGenerationException(
        'Music provider returned a non-instrumental artifact.',
      );
    }
    final contentType = draft.contentType.trim().toLowerCase();
    final baseType = contentType.split(';').first.trim();
    if (!_acceptedAudioTypes.contains(baseType)) {
      throw MusicGenerationException(
        'Unexpected music content type: ${draft.contentType}',
      );
    }

    final renderingId = MusicRenderingId.generate();
    final mediaReference = await _mediaStorage.store(
      StoreStoryMediaRequest(
        bytes: draft.audioBytes,
        contentType: draft.contentType.trim(),
        suggestedKey: 'lab_music_${plan.storyId.value}_${renderingId.value}',
      ),
    );

    final promptDigest = sha256.convert(utf8.encode(prompt)).toString();
    final rendering = MusicRendering(
      id: renderingId,
      storyId: plan.storyId,
      experiencePlanId: plan.id,
      experiencePlanProcessingVersion: plan.processingVersion,
      mediaReference: mediaReference,
      contentType: draft.contentType.trim(),
      byteLength: draft.audioBytes.length,
      duration: draft.duration,
      createdAt: at,
      providerLabel: draft.providerLabel,
      modelLabel: draft.modelLabel,
      generationId: draft.generationId,
      promptDigest: promptDigest,
      processingVersion: draft.processingVersion?.trim().isNotEmpty == true
          ? draft.processingVersion!.trim()
          : MusicRendering.defaultProcessingVersion,
      instrumental: true,
    );
    await _musicRenderingRepository.save(rendering);
    return rendering;
  }

  static int _defaultDurationSeconds(StoryExperiencePlan plan) {
    // Conservative default for Strategy A when recording duration is unknown
    // at generation time; playback rebuilds timeline from real duration.
    return 90;
  }
}

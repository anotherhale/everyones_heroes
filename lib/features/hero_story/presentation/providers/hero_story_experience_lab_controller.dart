import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/load_owned_story_media_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/run_experience_lab_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/update_story_consent_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/run_experience_lab_response.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/story_media_bytes.dart';
import 'package:everyonesheroes/features/hero_story/application/lab/experience_render_manifest.dart';
import 'package:everyonesheroes/features/hero_story/application/playback/story_experience_demo_stem.dart';
import 'package:everyonesheroes/features/hero_story/application/playback/story_experience_player.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/media/story_media_storage_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/playback/story_experience_player_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/experience_lab_run_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/experience_render_manifest_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/music_rendering_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_experience_plan_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_voice_rendering_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/capture_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/experience_lab_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/owned_story_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/experience_lab_provider_config.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/experience_lab_run.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_story_experience_playback_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_story_playback_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_story_voice_rendering_controller.dart';

/// UI phase for Experiment A laboratory experience.
enum HeroStoryExperienceLabPhase {
  idle,
  consentNeeded,
  generating,
  ready,
  playing,
  paused,
  silenced,
  failed,
}

@immutable
final class HeroStoryExperienceLabState {
  const HeroStoryExperienceLabState({
    this.phase = HeroStoryExperienceLabPhase.idle,
    this.labRunId,
    this.statusLabel,
    this.providerSummary,
    this.hasMusicConsent = false,
    this.hasVoiceConsent = false,
    this.hasPlayableArtifact = false,
    this.progressMessage,
    this.errorMessage,
  });

  final HeroStoryExperienceLabPhase phase;
  final String? labRunId;
  final String? statusLabel;
  final String? providerSummary;
  final bool hasMusicConsent;
  final bool hasVoiceConsent;
  final bool hasPlayableArtifact;
  final String? progressMessage;
  final String? errorMessage;

  bool get isGenerating => phase == HeroStoryExperienceLabPhase.generating;

  bool get canGenerate =>
      !isGenerating &&
      phase != HeroStoryExperienceLabPhase.playing &&
      phase != HeroStoryExperienceLabPhase.paused &&
      phase != HeroStoryExperienceLabPhase.silenced;

  bool get hasRequiredConsent => hasMusicConsent && hasVoiceConsent;

  HeroStoryExperienceLabState copyWith({
    HeroStoryExperienceLabPhase? phase,
    String? labRunId,
    String? statusLabel,
    String? providerSummary,
    bool? hasMusicConsent,
    bool? hasVoiceConsent,
    bool? hasPlayableArtifact,
    String? progressMessage,
    String? errorMessage,
    bool clearError = false,
    bool clearProgress = false,
  }) {
    return HeroStoryExperienceLabState(
      phase: phase ?? this.phase,
      labRunId: labRunId ?? this.labRunId,
      statusLabel: statusLabel ?? this.statusLabel,
      providerSummary: providerSummary ?? this.providerSummary,
      hasMusicConsent: hasMusicConsent ?? this.hasMusicConsent,
      hasVoiceConsent: hasVoiceConsent ?? this.hasVoiceConsent,
      hasPlayableArtifact: hasPlayableArtifact ?? this.hasPlayableArtifact,
      progressMessage:
          clearProgress ? null : (progressMessage ?? this.progressMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final heroStoryExperienceLabProvider = NotifierProvider.autoDispose
    .family<HeroStoryExperienceLabController, HeroStoryExperienceLabState,
        String>(
  HeroStoryExperienceLabController.new,
);

/// Experiment A laboratory controller.
///
/// Generation is explicit. Playback loads persisted artifacts only — never
/// calls creative direction, TTS, or music providers again.
final class HeroStoryExperienceLabController
    extends Notifier<HeroStoryExperienceLabState> {
  HeroStoryExperienceLabController(this.storyIdValue);

  final String storyIdValue;

  StoryExperiencePlayer? _player;
  StreamSubscription<StoryExperiencePlaybackSnapshot>? _snapshots;
  ExperienceLabRun? _loadedRun;
  ExperienceRenderManifest? _loadedManifest;

  static const consentRequiredMessage =
      'Authorize AI voice narration and AI music generation before creating '
      'an experimental AI experience. This sends presentation material to '
      'external providers via the EH AI proxy. Generated audio is presentation '
      'only — not your Story.';

  static const generatingMessage =
      'Generating experimental AI experience… creative direction, narration, '
      'and instrumental music bed. This may take a minute.';

  static const generationError =
      'Unable to generate the experimental AI experience. Provider failures '
      'are shown explicitly — demo music is not substituted. Your original '
      'recording remains available.';

  static const playbackError =
      'Unable to play the experimental AI experience. Persisted artifacts '
      'were not regenerated. Your original recording remains available.';

  @override
  HeroStoryExperienceLabState build() {
    final player = ref.watch(storyExperiencePlayerFactoryProvider).create();
    _player = player;
    _snapshots = player.snapshots.listen(_onSnapshot);
    ref.onDispose(() {
      unawaited(_snapshots?.cancel());
      unawaited(player.dispose());
      _player = null;
    });
    Future.microtask(_hydrate);
    return const HeroStoryExperienceLabState();
  }

  Future<void> _hydrate() async {
    final story = await ref
        .read(storyRepositoryProvider)
        .findById(StoryId(storyIdValue));
    final hasVoice = story?.consent.isVoiceRenderingApproved ?? false;
    final hasMusic = story?.consent.isMusicGenerationApproved ?? false;

    final run = await ref
        .read(experienceLabRunRepositoryProvider)
        .findByStoryId(StoryId(storyIdValue));

    if (run != null && run.isPlayable) {
      _loadedRun = run;
      if (run.renderManifestId != null) {
        _loadedManifest = await ref
            .read(experienceRenderManifestRepositoryProvider)
            .findById(run.renderManifestId!);
      }
      state = state.copyWith(
        phase: HeroStoryExperienceLabPhase.ready,
        labRunId: run.id.value,
        statusLabel: run.status.name,
        providerSummary: _providerSummary(run),
        hasVoiceConsent: hasVoice,
        hasMusicConsent: hasMusic,
        hasPlayableArtifact: true,
        clearError: true,
      );
      return;
    }

    state = state.copyWith(
      phase: hasVoice && hasMusic
          ? HeroStoryExperienceLabPhase.idle
          : HeroStoryExperienceLabPhase.consentNeeded,
      hasVoiceConsent: hasVoice,
      hasMusicConsent: hasMusic,
      hasPlayableArtifact: false,
    );
  }

  Future<void> grantLabConsents() async {
    await ref.read(updateStoryConsentUseCaseProvider).execute(
          UpdateStoryConsentRequest(
            storyId: StoryId(storyIdValue),
            grantVoiceRendering: true,
            grantMusicGeneration: true,
          ),
        );
    await _hydrate();
  }

  Future<void> generate({bool isRetry = false}) async {
    state = state.copyWith(
      phase: HeroStoryExperienceLabPhase.generating,
      progressMessage: generatingMessage,
      clearError: true,
    );

    try {
      final hero = await ref.read(ensureActiveLocalHeroProvider.future);
      final result = await ref.read(runExperienceLabUseCaseProvider).execute(
            RunExperienceLabRequest(
              storyId: StoryId(storyIdValue),
              ownerHeroId: hero.id,
              config: ExperienceLabProviderConfig.experimentA(),
              forceRegenerate: isRetry,
            ),
          );

      if (result is Success<RunExperienceLabResponse>) {
        _applySuccess(result.value);
      } else {
        final error = (result as Failure<RunExperienceLabResponse>).error;
        state = state.copyWith(
          phase: HeroStoryExperienceLabPhase.failed,
          errorMessage: error.isNotEmpty ? error : generationError,
          clearProgress: true,
        );
      }
    } catch (_) {
      state = state.copyWith(
        phase: HeroStoryExperienceLabPhase.failed,
        errorMessage: generationError,
        clearProgress: true,
      );
    }
  }

  void _applySuccess(RunExperienceLabResponse response) {
    _loadedRun = response.labRun;
    _loadedManifest = response.manifest;
    state = state.copyWith(
      phase: HeroStoryExperienceLabPhase.ready,
      labRunId: response.labRun.id.value,
      statusLabel: response.labRun.status.name,
      providerSummary: _providerSummary(response.labRun),
      hasPlayableArtifact: true,
      clearProgress: true,
      clearError: true,
    );
  }

  Future<void> playLabExperience({
    required String originalRecordingId,
  }) async {
    state = state.copyWith(
      phase: HeroStoryExperienceLabPhase.generating,
      progressMessage: 'Loading experimental AI experience…',
      clearError: true,
    );

    try {
      await ref.read(heroStoryPlaybackProvider(storyIdValue).notifier).stop();
      await ref
          .read(heroStoryExperiencePlaybackProvider(storyIdValue).notifier)
          .stop();
      await ref
          .read(heroStoryVoiceRenderingProvider(storyIdValue).notifier)
          .stop();

      final player = _player;
      if (player == null) {
        throw StateError('Lab experience player unavailable.');
      }

      final run = _loadedRun ??
          await ref
              .read(experienceLabRunRepositoryProvider)
              .findByStoryId(StoryId(storyIdValue));
      if (run == null || !run.isPlayable || run.musicRenderingId == null) {
        state = state.copyWith(
          phase: HeroStoryExperienceLabPhase.failed,
          errorMessage: 'Generate an AI experience before playing.',
          clearProgress: true,
        );
        return;
      }

      final manifest = _loadedManifest ??
          (run.renderManifestId == null
              ? null
              : await ref
                  .read(experienceRenderManifestRepositoryProvider)
                  .findById(run.renderManifestId!));
      if (manifest == null) {
        state = state.copyWith(
          phase: HeroStoryExperienceLabPhase.failed,
          errorMessage: 'Render manifest missing — regenerate the lab run.',
          clearProgress: true,
        );
        return;
      }
      final missing = manifest.missingArtifactLabels();
      if (missing.isNotEmpty) {
        state = state.copyWith(
          phase: HeroStoryExperienceLabPhase.failed,
          errorMessage: 'Missing lab artifacts: ${missing.join(', ')}',
          clearProgress: true,
        );
        return;
      }

      final plan = await ref
          .read(storyExperiencePlanRepositoryProvider)
          .findByStoryId(StoryId(storyIdValue));
      if (plan == null) {
        state = state.copyWith(
          phase: HeroStoryExperienceLabPhase.failed,
          errorMessage: 'StoryExperiencePlan missing.',
          clearProgress: true,
        );
        return;
      }

      final music = await ref
          .read(musicRenderingRepositoryProvider)
          .findById(run.musicRenderingId!);
      if (music == null) {
        state = state.copyWith(
          phase: HeroStoryExperienceLabPhase.failed,
          errorMessage: 'Music rendering artifact missing.',
          clearProgress: true,
        );
        return;
      }

      // Playback must never regenerate — load persisted bytes only.
      final mediaStorage = ref.read(storyMediaStoragePortProvider);
      final musicBytes = await mediaStorage.retrieve(music.mediaReference);
      if (musicBytes == null || musicBytes.isEmpty) {
        throw StateError('Persisted music bytes are empty.');
      }

      final recordingBytes = await _loadRecordingBytes(originalRecordingId);

      Uint8List? voiceBytes;
      if (run.voiceRenderingId != null) {
        final voice = await ref
            .read(storyVoiceRenderingRepositoryProvider)
            .findById(run.voiceRenderingId!);
        if (voice != null) {
          final loaded = await mediaStorage.retrieve(voice.mediaReference);
          if (loaded != null && loaded.isNotEmpty) {
            voiceBytes = loaded;
          }
        }
      }

      final volumes = <StoryExperiencePresentationPurpose, double>{
        for (final cue in manifest.cues) cue.purpose: cue.musicVolume,
      };

      final transcriptLength = plan.keyMoments
          .map((m) => m.sourceSpan.endOffset ?? 0)
          .fold<int>(0, (a, b) => a > b ? a : b);

      await player.load(
        originalRecordingBytes: recordingBytes,
        plan: plan,
        transcriptLength: transcriptLength > 0 ? transcriptLength : null,
        presentationVoiceBytes: voiceBytes,
        generatedMusicBytes: musicBytes,
        musicVolumesByPurpose: volumes,
      );

      _loadedRun = run;
      _loadedManifest = manifest;
      await player.play();
      state = state.copyWith(
        phase: HeroStoryExperienceLabPhase.playing,
        clearProgress: true,
      );
    } catch (_) {
      state = state.copyWith(
        phase: HeroStoryExperienceLabPhase.failed,
        errorMessage: playbackError,
        clearProgress: true,
      );
    }
  }

  Future<Uint8List> _loadRecordingBytes(String representationIdValue) async {
    final hero = await ref.read(ensureActiveLocalHeroProvider.future);
    final result = await ref.read(loadOwnedStoryMediaUseCaseProvider).execute(
          LoadOwnedStoryMediaRequest(
            storyId: StoryId(storyIdValue),
            ownerHeroId: hero.id,
            representationId: StoryRepresentationId(representationIdValue),
          ),
        );
    if (result is Success<StoryMediaBytes>) {
      return result.value.bytes;
    }
    throw StateError((result as Failure<StoryMediaBytes>).error);
  }

  Future<void> pause() async {
    await _player?.pause();
    state = state.copyWith(phase: HeroStoryExperienceLabPhase.paused);
  }

  Future<void> resume({required String originalRecordingId}) async {
    if (state.phase == HeroStoryExperienceLabPhase.paused) {
      await _player?.play();
      state = state.copyWith(phase: HeroStoryExperienceLabPhase.playing);
      return;
    }
    await playLabExperience(originalRecordingId: originalRecordingId);
  }

  Future<void> stop() async {
    await _player?.stop();
    state = state.copyWith(
      phase: state.hasPlayableArtifact
          ? HeroStoryExperienceLabPhase.ready
          : HeroStoryExperienceLabPhase.idle,
      clearError: true,
      clearProgress: true,
    );
  }

  void _onSnapshot(StoryExperiencePlaybackSnapshot snapshot) {
    final phase = switch (snapshot.phase) {
      StoryExperiencePlaybackPhase.playing =>
        HeroStoryExperienceLabPhase.playing,
      StoryExperiencePlaybackPhase.paused => HeroStoryExperienceLabPhase.paused,
      StoryExperiencePlaybackPhase.silenced =>
        HeroStoryExperienceLabPhase.silenced,
      StoryExperiencePlaybackPhase.completed =>
        HeroStoryExperienceLabPhase.ready,
      StoryExperiencePlaybackPhase.failed => HeroStoryExperienceLabPhase.failed,
      StoryExperiencePlaybackPhase.idle ||
      StoryExperiencePlaybackPhase.loading =>
        state.phase,
    };
    state = state.copyWith(
      phase: phase,
      errorMessage: snapshot.errorMessage,
    );
  }

  static String _providerSummary(ExperienceLabRun run) {
    final c = run.config;
    return 'Experiment A · creative ${c.creativeProvider}/${c.creativeModel} · '
        'voice ${c.voiceProvider}/${c.voiceModel} · '
        'music ${c.musicProvider}/${c.musicModel}';
  }
}

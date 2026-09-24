import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_voice_rendering_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/render_story_voice_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/update_story_consent_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/render_story_voice_response.dart';
import 'package:everyonesheroes/features/hero_story/application/playback/original_recording_player.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/media/story_media_storage_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/playback/original_recording_player_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_voice_rendering_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/capture_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/story_voice_rendering_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/voice_rendering_mode.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_voice_rendering.dart';
import 'package:everyonesheroes/features/hero_story/presentation/models/story_voice_rendering_view_data.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_story_experience_playback_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_story_playback_controller.dart';

/// UI phase for Create narrated version / Play narrated version.
enum HeroStoryVoiceRenderingPhase {
  idle,
  consentNeeded,
  rendering,
  ready,
  playing,
  paused,
  failed,
}

@immutable
final class HeroStoryVoiceRenderingState {
  const HeroStoryVoiceRenderingState({
    this.phase = HeroStoryVoiceRenderingPhase.idle,
    this.rendering,
    this.hasVoiceRenderingConsent = false,
    this.errorMessage,
  });

  final HeroStoryVoiceRenderingPhase phase;
  final StoryVoiceRenderingViewData? rendering;
  final bool hasVoiceRenderingConsent;
  final String? errorMessage;

  bool get isRendering => phase == HeroStoryVoiceRenderingPhase.rendering;

  bool get isPlaying => phase == HeroStoryVoiceRenderingPhase.playing;

  bool get canCreate =>
      !isRendering &&
      phase != HeroStoryVoiceRenderingPhase.playing &&
      phase != HeroStoryVoiceRenderingPhase.paused;

  bool get hasArtifact => rendering != null;

  HeroStoryVoiceRenderingState copyWith({
    HeroStoryVoiceRenderingPhase? phase,
    StoryVoiceRenderingViewData? rendering,
    bool? hasVoiceRenderingConsent,
    String? errorMessage,
    bool clearError = false,
    bool clearRendering = false,
  }) {
    return HeroStoryVoiceRenderingState(
      phase: phase ?? this.phase,
      rendering: clearRendering ? null : (rendering ?? this.rendering),
      hasVoiceRenderingConsent:
          hasVoiceRenderingConsent ?? this.hasVoiceRenderingConsent,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final heroStoryVoiceRenderingProvider = NotifierProvider.autoDispose
    .family<HeroStoryVoiceRenderingController, HeroStoryVoiceRenderingState,
        String>(
  HeroStoryVoiceRenderingController.new,
);

/// Explicit AI voice rendering for Hero Story (HS.12.6).
///
/// Does not auto-generate on open/save/plan/play. Playback loads a previously
/// persisted artifact and never invokes the voice-rendering port again.
final class HeroStoryVoiceRenderingController
    extends Notifier<HeroStoryVoiceRenderingState> {
  HeroStoryVoiceRenderingController(this.storyIdValue);

  final String storyIdValue;

  OriginalRecordingPlayer? _player;
  StreamSubscription<OriginalRecordingPlaybackSnapshot>? _snapshots;
  StoryVoiceRenderingId? _loadedArtifactId;
  bool _loadAttempted = false;

  static const renderingMessage =
      'Creating a synthetic narrated version of your experience…';
  static const consentRequiredMessage =
      'Explicit voice-rendering authorization is required before creating a '
      'narrated version. Recording, transcription, or AI consent alone is not '
      'enough.';
  static const renderError =
      'Unable to create a narrated version right now. Your original recording '
      'is still available.';
  static const playbackError =
      'Unable to play the narrated version right now. Your original recording '
      'is still available.';

  @override
  HeroStoryVoiceRenderingState build() {
    final player = ref.watch(originalRecordingPlayerFactoryProvider).create();
    _player = player;
    _snapshots = player.snapshots.listen(_onSnapshot);
    ref.onDispose(() {
      unawaited(_snapshots?.cancel());
      unawaited(player.dispose());
      _player = null;
    });
    Future.microtask(_hydrate);
    return const HeroStoryVoiceRenderingState();
  }

  Future<void> _hydrate() async {
    if (_loadAttempted) {
      return;
    }
    _loadAttempted = true;
    try {
      final story = await ref
          .read(storyRepositoryProvider)
          .findById(StoryId(storyIdValue));
      final hasConsent = story?.consent.isVoiceRenderingApproved ?? false;
      final existing = await ref
          .read(storyVoiceRenderingRepositoryProvider)
          .findByStoryId(StoryId(storyIdValue));
      if (existing != null) {
        state = state.copyWith(
          phase: HeroStoryVoiceRenderingPhase.ready,
          rendering: _toViewData(existing),
          hasVoiceRenderingConsent: hasConsent,
          clearError: true,
        );
      } else {
        state = state.copyWith(
          phase: hasConsent
              ? HeroStoryVoiceRenderingPhase.idle
              : HeroStoryVoiceRenderingPhase.consentNeeded,
          hasVoiceRenderingConsent: hasConsent,
          clearError: true,
        );
      }
    } catch (_) {
      // Leave idle; user can still attempt create.
    }
  }

  Future<void> grantVoiceRenderingConsent() async {
    state = state.copyWith(clearError: true);
    final result = await ref.read(updateStoryConsentUseCaseProvider).execute(
          UpdateStoryConsentRequest(
            storyId: StoryId(storyIdValue),
            grantVoiceRendering: true,
          ),
        );
    if (result is Failure<Story>) {
      state = state.copyWith(
        phase: HeroStoryVoiceRenderingPhase.failed,
        errorMessage: result.error,
      );
      return;
    }
    state = state.copyWith(
      hasVoiceRenderingConsent: true,
      phase: state.rendering == null
          ? HeroStoryVoiceRenderingPhase.idle
          : HeroStoryVoiceRenderingPhase.ready,
      clearError: true,
    );
  }

  Future<void> createNarratedVersion({bool isRetry = false}) async {
    state = state.copyWith(
      phase: HeroStoryVoiceRenderingPhase.rendering,
      clearError: true,
    );

    try {
      final story = await ref
          .read(storyRepositoryProvider)
          .findById(StoryId(storyIdValue));
      if (story == null) {
        state = state.copyWith(
          phase: HeroStoryVoiceRenderingPhase.failed,
          errorMessage: renderError,
        );
        return;
      }

      if (!story.consent.isVoiceRenderingApproved) {
        state = state.copyWith(
          phase: HeroStoryVoiceRenderingPhase.consentNeeded,
          hasVoiceRenderingConsent: false,
          errorMessage: consentRequiredMessage,
        );
        return;
      }

      final owner = await ref.read(ensureActiveLocalHeroProvider.future);
      final result = await ref.read(renderStoryVoiceUseCaseProvider).execute(
            RenderStoryVoiceAppRequest(
              storyId: StoryId(storyIdValue),
              ownerHeroId: owner.id,
              renderingMode: VoiceRenderingMode.syntheticNarration,
              forceRegenerate: isRetry || state.rendering != null,
            ),
          );

      if (result is Failure<RenderStoryVoiceResponse>) {
        state = state.copyWith(
          phase: HeroStoryVoiceRenderingPhase.failed,
          errorMessage: result.error,
          hasVoiceRenderingConsent: true,
        );
        return;
      }

      final response = (result as Success<RenderStoryVoiceResponse>).value;
      state = state.copyWith(
        phase: HeroStoryVoiceRenderingPhase.ready,
        rendering: _toViewData(response.rendering),
        hasVoiceRenderingConsent: true,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        phase: HeroStoryVoiceRenderingPhase.failed,
        errorMessage: renderError,
      );
    }
  }

  Future<void> playNarratedVersion() async {
    final artifact = state.rendering;
    if (artifact == null) {
      state = state.copyWith(
        phase: HeroStoryVoiceRenderingPhase.failed,
        errorMessage: 'Create a narrated version before playing it.',
      );
      return;
    }

    state = state.copyWith(clearError: true);

    try {
      await ref.read(heroStoryPlaybackProvider(storyIdValue).notifier).stop();
      try {
        await ref
            .read(heroStoryExperiencePlaybackProvider(storyIdValue).notifier)
            .stop();
      } catch (_) {
        // Experience player may be unbound when no plan exists.
      }

      final player = _player;
      if (player == null) {
        throw StateError('Narrated playback player is unavailable.');
      }

      if (_loadedArtifactId != artifact.id) {
        final persisted = await ref
            .read(storyVoiceRenderingRepositoryProvider)
            .findById(artifact.id);
        if (persisted == null) {
          state = state.copyWith(
            phase: HeroStoryVoiceRenderingPhase.failed,
            errorMessage: playbackError,
          );
          return;
        }
        final bytes =
            await ref.read(storyMediaStoragePortProvider).retrieve(
                  persisted.mediaReference,
                );
        if (bytes == null || bytes.isEmpty) {
          state = state.copyWith(
            phase: HeroStoryVoiceRenderingPhase.failed,
            errorMessage: playbackError,
          );
          return;
        }
        await player.load(Uint8List.fromList(bytes));
        _loadedArtifactId = artifact.id;
      }

      await player.play();
      state = state.copyWith(phase: HeroStoryVoiceRenderingPhase.playing);
    } catch (_) {
      state = state.copyWith(
        phase: HeroStoryVoiceRenderingPhase.failed,
        errorMessage: playbackError,
      );
    }
  }

  Future<void> pause() async {
    await _player?.pause();
    state = state.copyWith(phase: HeroStoryVoiceRenderingPhase.paused);
  }

  Future<void> resume() async {
    if (state.phase == HeroStoryVoiceRenderingPhase.paused) {
      await _player?.play();
      state = state.copyWith(phase: HeroStoryVoiceRenderingPhase.playing);
      return;
    }
    await playNarratedVersion();
  }

  Future<void> stop() async {
    await _player?.stop();
    state = state.copyWith(
      phase: state.rendering == null
          ? HeroStoryVoiceRenderingPhase.idle
          : HeroStoryVoiceRenderingPhase.ready,
      clearError: true,
    );
  }

  void _onSnapshot(OriginalRecordingPlaybackSnapshot snapshot) {
    switch (snapshot.phase) {
      case OriginalRecordingPlaybackPhase.playing:
        state = state.copyWith(phase: HeroStoryVoiceRenderingPhase.playing);
      case OriginalRecordingPlaybackPhase.paused:
        state = state.copyWith(phase: HeroStoryVoiceRenderingPhase.paused);
      case OriginalRecordingPlaybackPhase.completed:
        state = state.copyWith(phase: HeroStoryVoiceRenderingPhase.ready);
      case OriginalRecordingPlaybackPhase.failed:
        state = state.copyWith(
          phase: HeroStoryVoiceRenderingPhase.failed,
          errorMessage: snapshot.errorMessage ?? playbackError,
        );
      case OriginalRecordingPlaybackPhase.idle:
        break;
    }
  }

  static StoryVoiceRenderingViewData _toViewData(
    StoryVoiceRendering rendering,
  ) {
    return StoryVoiceRenderingViewData(
      id: rendering.id,
      experiencePlanId: rendering.experiencePlanId.value,
      experiencePlanProcessingVersion:
          rendering.experiencePlanProcessingVersion,
      sourceRepresentationId: rendering.sourceRepresentationId.value,
      renderingMode: rendering.renderingMode,
      contentType: rendering.contentType,
      byteLength: rendering.byteLength,
      createdAt: rendering.createdAt,
      providerLabel: rendering.providerLabel,
      modelLabel: rendering.modelLabel,
    );
  }
}

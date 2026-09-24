import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/load_owned_story_media_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/story_media_bytes.dart';
import 'package:everyonesheroes/features/hero_story/application/playback/story_experience_demo_stem.dart';
import 'package:everyonesheroes/features/hero_story/application/playback/story_experience_player.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/playback/story_experience_player_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_experience_plan_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/owned_story_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_plan.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_story_playback_controller.dart';

/// UI phase for "Play my experience" on Hero Story.
enum HeroStoryExperiencePlaybackPhase {
  idle,
  loading,
  playing,
  paused,
  silenced,
  completed,
  failed,
}

@immutable
final class HeroStoryExperiencePlaybackState {
  const HeroStoryExperiencePlaybackState({
    this.phase = HeroStoryExperiencePlaybackPhase.idle,
    this.purposeLabel,
    this.errorMessage,
  });

  final HeroStoryExperiencePlaybackPhase phase;
  final String? purposeLabel;
  final String? errorMessage;

  bool get isBusy => phase == HeroStoryExperiencePlaybackPhase.loading;

  bool get isActive =>
      phase == HeroStoryExperiencePlaybackPhase.playing ||
      phase == HeroStoryExperiencePlaybackPhase.paused ||
      phase == HeroStoryExperiencePlaybackPhase.silenced;

  HeroStoryExperiencePlaybackState copyWith({
    HeroStoryExperiencePlaybackPhase? phase,
    String? purposeLabel,
    String? errorMessage,
    bool clearError = false,
    bool clearPurpose = false,
  }) {
    return HeroStoryExperiencePlaybackState(
      phase: phase ?? this.phase,
      purposeLabel:
          clearPurpose ? null : (purposeLabel ?? this.purposeLabel),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final heroStoryExperiencePlaybackProvider = NotifierProvider.autoDispose
    .family<HeroStoryExperiencePlaybackController,
        HeroStoryExperiencePlaybackState, String>(
  HeroStoryExperiencePlaybackController.new,
);

/// Plays a persisted Story Experience Plan with the original recording.
///
/// Does not regenerate the plan, call AI, or mutate Story / transcript /
/// CapturedStoryReading.
final class HeroStoryExperiencePlaybackController
    extends Notifier<HeroStoryExperiencePlaybackState> {
  HeroStoryExperiencePlaybackController(this.storyIdValue);

  final String storyIdValue;

  StoryExperiencePlayer? _player;
  StreamSubscription<StoryExperiencePlaybackSnapshot>? _snapshots;
  StoryExperiencePlan? _loadedPlan;
  StoryRepresentationId? _loadedRecordingId;

  static const playbackError =
      'Unable to play your experience right now. Your original recording is '
      'still available.';
  static const missingPlanError =
      'Create my experience first so there is a plan to play.';
  static const missingRecordingError =
      'No original recording is available for this experience.';

  @override
  HeroStoryExperiencePlaybackState build() {
    final player = ref.watch(storyExperiencePlayerFactoryProvider).create();
    _player = player;
    _snapshots = player.snapshots.listen(_onSnapshot);
    ref.onDispose(() {
      unawaited(_snapshots?.cancel());
      unawaited(player.dispose());
      _player = null;
    });
    return const HeroStoryExperiencePlaybackState();
  }

  Future<void> playExperience({
    required StoryRepresentationId originalRecordingId,
  }) async {
    state = state.copyWith(
      phase: HeroStoryExperiencePlaybackPhase.loading,
      clearError: true,
      clearPurpose: true,
    );

    try {
      // Stop plain original playback so the two surfaces do not compete.
      await ref.read(heroStoryPlaybackProvider(storyIdValue).notifier).stop();

      final player = _player;
      if (player == null) {
        throw StateError('Experience player is unavailable.');
      }

      final plan = await ref
          .read(storyExperiencePlanRepositoryProvider)
          .findByStoryId(StoryId(storyIdValue));
      if (plan == null) {
        state = state.copyWith(
          phase: HeroStoryExperiencePlaybackPhase.failed,
          errorMessage: missingPlanError,
        );
        return;
      }

      final needsReload = _loadedPlan?.id != plan.id ||
          _loadedRecordingId != originalRecordingId;
      if (needsReload) {
        final bytes = await _loadOriginalBytes(originalRecordingId);
        // Infer transcript length from plan spans for proportional timing.
        final transcriptLength = plan.keyMoments
            .map((m) => m.sourceSpan.endOffset ?? 0)
            .fold<int>(0, (a, b) => a > b ? a : b);
        await player.load(
          originalRecordingBytes: bytes,
          plan: plan,
          transcriptLength: transcriptLength > 0 ? transcriptLength : null,
        );
        _loadedPlan = plan;
        _loadedRecordingId = originalRecordingId;
      }

      await player.play();
      if (state.phase != HeroStoryExperiencePlaybackPhase.failed) {
        state = state.copyWith(phase: HeroStoryExperiencePlaybackPhase.playing);
      }
    } catch (_) {
      state = state.copyWith(
        phase: HeroStoryExperiencePlaybackPhase.failed,
        errorMessage: playbackError,
      );
    }
  }

  Future<void> pause() async {
    await _player?.pause();
    state = state.copyWith(phase: HeroStoryExperiencePlaybackPhase.paused);
  }

  Future<void> resume({
    required StoryRepresentationId originalRecordingId,
  }) async {
    if (state.phase == HeroStoryExperiencePlaybackPhase.paused) {
      await _player?.play();
      state = state.copyWith(phase: HeroStoryExperiencePlaybackPhase.playing);
      return;
    }
    await playExperience(originalRecordingId: originalRecordingId);
  }

  Future<void> stop() async {
    await _player?.stop();
    state = state.copyWith(
      phase: HeroStoryExperiencePlaybackPhase.idle,
      clearError: true,
      clearPurpose: true,
    );
  }

  Future<Uint8List> _loadOriginalBytes(
    StoryRepresentationId representationId,
  ) async {
    final hero = await ref.read(ensureActiveLocalHeroProvider.future);
    final result = await ref
        .read(loadOwnedStoryMediaUseCaseProvider)
        .execute(
          LoadOwnedStoryMediaRequest(
            storyId: StoryId(storyIdValue),
            representationId: representationId,
            ownerHeroId: hero.id,
          ),
        );
    if (result is Failure<StoryMediaBytes>) {
      throw StateError(result.error);
    }
    return (result as Success<StoryMediaBytes>).value.bytes;
  }

  void _onSnapshot(StoryExperiencePlaybackSnapshot snapshot) {
    switch (snapshot.phase) {
      case StoryExperiencePlaybackPhase.completed:
        state = state.copyWith(
          phase: HeroStoryExperiencePlaybackPhase.completed,
          purposeLabel: _labelFor(snapshot.purpose),
        );
      case StoryExperiencePlaybackPhase.failed:
        state = state.copyWith(
          phase: HeroStoryExperiencePlaybackPhase.failed,
          errorMessage: snapshot.errorMessage ?? playbackError,
        );
      case StoryExperiencePlaybackPhase.playing:
        state = state.copyWith(
          phase: HeroStoryExperiencePlaybackPhase.playing,
          purposeLabel: _labelFor(snapshot.purpose),
        );
      case StoryExperiencePlaybackPhase.paused:
        state = state.copyWith(
          phase: HeroStoryExperiencePlaybackPhase.paused,
          purposeLabel: _labelFor(snapshot.purpose),
        );
      case StoryExperiencePlaybackPhase.silenced:
        state = state.copyWith(
          phase: HeroStoryExperiencePlaybackPhase.silenced,
          purposeLabel: _labelFor(snapshot.purpose) ?? 'Intentional silence',
        );
      case StoryExperiencePlaybackPhase.idle:
      case StoryExperiencePlaybackPhase.loading:
        break;
    }
  }

  static String? _labelFor(StoryExperiencePresentationPurpose? purpose) {
    if (purpose == null) {
      return null;
    }
    return switch (purpose) {
      StoryExperiencePresentationPurpose.opening => 'Opening',
      StoryExperiencePresentationPurpose.challenge => 'Challenge',
      StoryExperiencePresentationPurpose.uncertainty => 'Uncertainty',
      StoryExperiencePresentationPurpose.turningPoint => 'Turning point',
      StoryExperiencePresentationPurpose.decision => 'Decision',
      StoryExperiencePresentationPurpose.resolution => 'Resolution',
      StoryExperiencePresentationPurpose.closing => 'Closing',
    };
  }
}

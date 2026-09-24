import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/load_owned_story_media_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/story_media_bytes.dart';
import 'package:everyonesheroes/features/hero_story/application/playback/original_recording_player.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/playback/original_recording_player_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/owned_story_use_case_providers.dart';

/// User-facing playback of the Hero's original recording.
enum HeroStoryPlaybackPhase {
  idle,
  loading,
  playing,
  paused,
  completed,
  failed,
}

@immutable
final class HeroStoryPlaybackState {
  const HeroStoryPlaybackState({
    this.phase = HeroStoryPlaybackPhase.idle,
    this.errorMessage,
  });

  final HeroStoryPlaybackPhase phase;
  final String? errorMessage;

  bool get isBusy => phase == HeroStoryPlaybackPhase.loading;

  HeroStoryPlaybackState copyWith({
    HeroStoryPlaybackPhase? phase,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HeroStoryPlaybackState(
      phase: phase ?? this.phase,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final heroStoryPlaybackProvider = NotifierProvider.autoDispose
    .family<HeroStoryPlaybackController, HeroStoryPlaybackState, String>(
      HeroStoryPlaybackController.new,
    );

/// Loads the original recording through [LoadOwnedStoryMediaUseCase] and
/// plays those bytes on [OriginalRecordingPlayer].
final class HeroStoryPlaybackController
    extends Notifier<HeroStoryPlaybackState> {
  HeroStoryPlaybackController(this.storyIdValue);

  final String storyIdValue;

  OriginalRecordingPlayer? _player;
  StreamSubscription<OriginalRecordingPlaybackSnapshot>? _snapshots;
  StoryRepresentationId? _loadedId;

  static const playbackError = 'Unable to play your original recording.';

  @override
  HeroStoryPlaybackState build() {
    final player = ref.watch(originalRecordingPlayerFactoryProvider).create();
    _player = player;
    _snapshots = player.snapshots.listen(_onSnapshot);
    ref.onDispose(() {
      unawaited(_snapshots?.cancel());
      unawaited(player.dispose());
      _player = null;
    });
    return const HeroStoryPlaybackState();
  }

  Future<void> playOriginal({
    required StoryRepresentationId representationId,
  }) async {
    state = state.copyWith(
      phase: HeroStoryPlaybackPhase.loading,
      clearError: true,
    );
    try {
      final player = _player;
      if (player == null) {
        throw StateError('Playback is unavailable.');
      }
      if (_loadedId != representationId) {
        final bytes = await _loadOriginalBytes(representationId);
        await player.load(bytes);
        _loadedId = representationId;
      }
      await player.play();
      if (state.phase != HeroStoryPlaybackPhase.failed) {
        state = state.copyWith(phase: HeroStoryPlaybackPhase.playing);
      }
    } catch (_) {
      state = state.copyWith(
        phase: HeroStoryPlaybackPhase.failed,
        errorMessage: playbackError,
      );
    }
  }

  Future<void> pause() async {
    await _player?.pause();
    state = state.copyWith(phase: HeroStoryPlaybackPhase.paused);
  }

  Future<void> stop() async {
    await _player?.stop();
    state = state.copyWith(
      phase: HeroStoryPlaybackPhase.idle,
      clearError: true,
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

  void _onSnapshot(OriginalRecordingPlaybackSnapshot snapshot) {
    switch (snapshot.phase) {
      case OriginalRecordingPlaybackPhase.completed:
        state = state.copyWith(phase: HeroStoryPlaybackPhase.completed);
      case OriginalRecordingPlaybackPhase.failed:
        state = state.copyWith(
          phase: HeroStoryPlaybackPhase.failed,
          errorMessage: snapshot.errorMessage ?? playbackError,
        );
      case OriginalRecordingPlaybackPhase.playing:
      case OriginalRecordingPlaybackPhase.paused:
      case OriginalRecordingPlaybackPhase.idle:
        break;
    }
  }
}

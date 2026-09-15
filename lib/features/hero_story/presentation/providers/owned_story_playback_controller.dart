import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/load_owned_story_media_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/story_media_bytes.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/owned_story_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/presentation/models/owned_story_labels.dart';

/// Playback UI state for an owned Story original recording.
@immutable
final class OwnedStoryPlaybackState {
  const OwnedStoryPlaybackState({
    this.isLoading = false,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.errorMessage,
  });

  final bool isLoading;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final String? errorMessage;

  String get positionLabel => OwnedStoryLabels.formatDuration(position);
  String get durationLabel => OwnedStoryLabels.formatDuration(duration);

  OwnedStoryPlaybackState copyWith({
    bool? isLoading,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OwnedStoryPlaybackState(
      isLoading: isLoading ?? this.isLoading,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final ownedStoryPlaybackProvider = NotifierProvider.autoDispose
    .family<OwnedStoryPlaybackController, OwnedStoryPlaybackState, String>(
      OwnedStoryPlaybackController.new,
    );

/// Loads owned media via [LoadOwnedStoryMediaUseCase] and plays with just_audio.
final class OwnedStoryPlaybackController
    extends Notifier<OwnedStoryPlaybackState> {
  OwnedStoryPlaybackController(this.storyIdValue);

  final String storyIdValue;

  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  bool _loaded = false;

  @override
  OwnedStoryPlaybackState build() {
    ref.onDispose(() {
      unawaited(_disposePlayer());
    });
    return const OwnedStoryPlaybackState();
  }

  Future<void> play({
    required StoryRepresentationId representationId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _ensureLoaded(representationId: representationId);
      await _player!.play();
      state = state.copyWith(isLoading: false, isPlaying: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isPlaying: false,
        errorMessage: 'Unable to play recording.',
      );
    }
  }

  Future<void> pause() async {
    await _player?.pause();
    state = state.copyWith(isPlaying: false);
  }

  Future<void> stop() async {
    await _player?.stop();
    await _player?.seek(Duration.zero);
    state = state.copyWith(isPlaying: false, position: Duration.zero);
  }

  Future<void> _ensureLoaded({
    required StoryRepresentationId representationId,
  }) async {
    if (_loaded && _player != null) {
      return;
    }

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
    final media = (result as Success<StoryMediaBytes>).value;

    _player ??= AudioPlayer();
    await _player!.setAudioSource(
      AudioSource.uri(
        Uri.dataFromBytes(media.bytes, mimeType: 'audio/mp4'),
      ),
    );

    await _playerStateSub?.cancel();
    await _positionSub?.cancel();
    await _durationSub?.cancel();

    _playerStateSub = _player!.playerStateStream.listen((playerState) {
      final completed =
          playerState.processingState == ProcessingState.completed;
      state = state.copyWith(
        isPlaying: playerState.playing && !completed,
        position: completed ? Duration.zero : state.position,
      );
      if (completed) {
        unawaited(_player!.seek(Duration.zero));
      }
    });
    _positionSub = _player!.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });
    _durationSub = _player!.durationStream.listen((duration) {
      if (duration != null) {
        state = state.copyWith(duration: duration);
      }
    });

    _loaded = true;
  }

  Future<void> _disposePlayer() async {
    await _playerStateSub?.cancel();
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    _playerStateSub = null;
    _positionSub = null;
    _durationSub = null;
    await _player?.dispose();
    _player = null;
    _loaded = false;
  }
}

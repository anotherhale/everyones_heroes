import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/understand_owned_hero_story_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/understand_owned_hero_story_response.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/captured_story_reading_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/captured_story_reading_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/presentation/models/captured_story_reading_view_data.dart';

enum HeroStoryUnderstandingPhase {
  idle,
  processing,
  ready,
  failed,
}

@immutable
final class HeroStoryUnderstandingUiState {
  const HeroStoryUnderstandingUiState({
    this.phase = HeroStoryUnderstandingPhase.idle,
    this.reading,
    this.errorMessage,
    this.didAttempt = false,
  });

  final HeroStoryUnderstandingPhase phase;
  final CapturedStoryReadingViewData? reading;
  final String? errorMessage;
  final bool didAttempt;

  bool get isProcessing => phase == HeroStoryUnderstandingPhase.processing;

  HeroStoryUnderstandingUiState copyWith({
    HeroStoryUnderstandingPhase? phase,
    CapturedStoryReadingViewData? reading,
    String? errorMessage,
    bool clearError = false,
    bool clearReading = false,
    bool? didAttempt,
  }) {
    return HeroStoryUnderstandingUiState(
      phase: phase ?? this.phase,
      reading: clearReading ? null : (reading ?? this.reading),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      didAttempt: didAttempt ?? this.didAttempt,
    );
  }
}

final heroStoryUnderstandingProvider = NotifierProvider.autoDispose
    .family<HeroStoryUnderstandingController, HeroStoryUnderstandingUiState,
        String>(
  HeroStoryUnderstandingController.new,
);

/// Explicit "Understand my story" flow for [HeroStoryScreen] (HS.12.3).
///
/// Does not auto-start on open. Leaves original recording playback available.
final class HeroStoryUnderstandingController
    extends Notifier<HeroStoryUnderstandingUiState> {
  HeroStoryUnderstandingController(this.storyIdValue);

  final String storyIdValue;

  static const String processingMessage =
      'Understanding your story from the original recording…';
  static const String failureFallback =
      'Unable to understand this story right now. '
      'Your original recording is still available.';

  @override
  HeroStoryUnderstandingUiState build() {
    Future.microtask(_loadExistingReading);
    return const HeroStoryUnderstandingUiState();
  }

  Future<void> _loadExistingReading() async {
    try {
      final existing = await ref
          .read(capturedStoryReadingRepositoryProvider)
          .findByStoryId(StoryId(storyIdValue));
      if (existing == null) {
        return;
      }
      if (state.phase == HeroStoryUnderstandingPhase.processing) {
        return;
      }
      state = state.copyWith(
        phase: HeroStoryUnderstandingPhase.ready,
        reading: CapturedStoryReadingViewData.fromReading(existing),
        clearError: true,
      );
    } catch (_) {
      // Existing reading is optional; silence load errors.
    }
  }

  Future<void> understand({bool isRetry = false}) async {
    if (state.isProcessing) {
      return;
    }

    final retry =
        isRetry || state.phase == HeroStoryUnderstandingPhase.failed;

    state = state.copyWith(
      phase: HeroStoryUnderstandingPhase.processing,
      clearError: true,
      didAttempt: true,
    );

    try {
      final hero = await ref.read(ensureActiveLocalHeroProvider.future);
      final result = await ref
          .read(understandOwnedHeroStoryUseCaseProvider)
          .execute(
            UnderstandOwnedHeroStoryRequest(
              storyId: StoryId(storyIdValue),
              ownerHeroId: hero.id,
              isRetry: retry,
            ),
          );

      if (result is Failure<UnderstandOwnedHeroStoryResponse>) {
        state = state.copyWith(
          phase: HeroStoryUnderstandingPhase.failed,
          errorMessage: result.error,
        );
        return;
      }

      final response =
          (result as Success<UnderstandOwnedHeroStoryResponse>).value;
      state = state.copyWith(
        phase: HeroStoryUnderstandingPhase.ready,
        reading: CapturedStoryReadingViewData.fromReading(response.reading),
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        phase: HeroStoryUnderstandingPhase.failed,
        errorMessage: '$failureFallback ($e)',
      );
    }
  }
}

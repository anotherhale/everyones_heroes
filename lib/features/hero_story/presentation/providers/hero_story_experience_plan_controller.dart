import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/generate_story_experience_plan_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/generate_story_experience_plan_response.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/captured_story_reading_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_experience_plan_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/story_experience_plan_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/presentation/models/story_experience_plan_view_data.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_story_understanding_controller.dart';

enum HeroStoryExperiencePlanPhase {
  idle,
  generating,
  success,
  failed,
}

@immutable
final class HeroStoryExperiencePlanUiState {
  const HeroStoryExperiencePlanUiState({
    this.phase = HeroStoryExperiencePlanPhase.idle,
    this.plan,
    this.errorMessage,
    this.readingAvailable = false,
  });

  final HeroStoryExperiencePlanPhase phase;
  final StoryExperiencePlanViewData? plan;
  final String? errorMessage;
  final bool readingAvailable;

  bool get isGenerating => phase == HeroStoryExperiencePlanPhase.generating;

  bool get canCreate => phase != HeroStoryExperiencePlanPhase.generating;

  HeroStoryExperiencePlanUiState copyWith({
    HeroStoryExperiencePlanPhase? phase,
    StoryExperiencePlanViewData? plan,
    String? errorMessage,
    bool clearError = false,
    bool clearPlan = false,
    bool? readingAvailable,
  }) {
    return HeroStoryExperiencePlanUiState(
      phase: phase ?? this.phase,
      plan: clearPlan ? null : (plan ?? this.plan),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      readingAvailable: readingAvailable ?? this.readingAvailable,
    );
  }
}

final heroStoryExperiencePlanProvider = NotifierProvider.autoDispose
    .family<HeroStoryExperiencePlanController, HeroStoryExperiencePlanUiState,
        String>(
  HeroStoryExperiencePlanController.new,
);

/// Explicit "Create my experience" flow for [HeroStoryScreen] (HS.12.4).
///
/// Available only when a CapturedStoryReading exists. Leaves original
/// recording playback available in every state.
final class HeroStoryExperiencePlanController
    extends Notifier<HeroStoryExperiencePlanUiState> {
  HeroStoryExperiencePlanController(this.storyIdValue);

  final String storyIdValue;

  static const String generatingMessage =
      'Creating your experience plan from the story understanding…';
  static const String failureFallback =
      'Unable to create an experience plan right now. '
      'Your original recording is still available.';

  @override
  HeroStoryExperiencePlanUiState build() {
    ref.listen(heroStoryUnderstandingProvider(storyIdValue), (previous, next) {
      if (next.reading != null && !state.readingAvailable) {
        state = state.copyWith(readingAvailable: true);
      }
    });
    Future.microtask(_hydrate);
    return const HeroStoryExperiencePlanUiState();
  }

  Future<void> _hydrate() async {
    try {
      final storyId = StoryId(storyIdValue);
      final reading = await ref
          .read(capturedStoryReadingRepositoryProvider)
          .findByStoryId(storyId);
      final existing = await ref
          .read(storyExperiencePlanRepositoryProvider)
          .findByStoryId(storyId);

      final understanding =
          ref.read(heroStoryUnderstandingProvider(storyIdValue));
      final readingAvailable =
          reading != null || understanding.reading != null;

      if (state.phase == HeroStoryExperiencePlanPhase.generating) {
        state = state.copyWith(readingAvailable: readingAvailable);
        return;
      }

      if (existing != null) {
        state = state.copyWith(
          phase: HeroStoryExperiencePlanPhase.success,
          plan: StoryExperiencePlanViewData.fromPlan(existing),
          readingAvailable: readingAvailable,
          clearError: true,
        );
        return;
      }

      state = state.copyWith(readingAvailable: readingAvailable);
    } catch (_) {
      // Optional hydrate; silence load errors.
    }
  }

  Future<void> create({bool isRetry = false}) async {
    if (state.isGenerating) {
      return;
    }

    final understanding =
        ref.read(heroStoryUnderstandingProvider(storyIdValue));
    if (!state.readingAvailable && understanding.reading == null) {
      state = state.copyWith(
        phase: HeroStoryExperiencePlanPhase.failed,
        errorMessage:
            'Understand your story first so a Captured Story Reading exists.',
      );
      return;
    }

    state = state.copyWith(
      phase: HeroStoryExperiencePlanPhase.generating,
      clearError: true,
      readingAvailable: true,
    );

    try {
      final result = await ref
          .read(generateStoryExperiencePlanUseCaseProvider)
          .execute(
            GenerateStoryExperiencePlanAppRequest(
              storyId: StoryId(storyIdValue),
              forceRegenerate: true,
            ),
          );

      if (result is Failure<GenerateStoryExperiencePlanResponse>) {
        state = state.copyWith(
          phase: HeroStoryExperiencePlanPhase.failed,
          errorMessage: result.error,
        );
        return;
      }

      final response =
          (result as Success<GenerateStoryExperiencePlanResponse>).value;
      state = state.copyWith(
        phase: HeroStoryExperiencePlanPhase.success,
        plan: StoryExperiencePlanViewData.fromPlan(response.plan),
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        phase: HeroStoryExperiencePlanPhase.failed,
        errorMessage: '$failureFallback ($e)',
      );
    }
  }
}

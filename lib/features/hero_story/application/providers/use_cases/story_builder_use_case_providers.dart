import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/eventing/event_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_builder_session_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/story_builder/story_builder_question_strategy_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/abandon_story_builder_session_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/advance_story_builder_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/answer_story_builder_prompt_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/complete_story_builder_session_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/edit_story_builder_response_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/get_story_builder_session_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/pause_story_builder_session_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/present_story_builder_prompt_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/resume_story_builder_session_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/set_story_builder_intent_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/set_story_builder_purpose_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/set_story_builder_themes_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/skip_story_builder_prompt_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/start_story_builder_session_use_case.dart';

final startStoryBuilderSessionUseCaseProvider =
    Provider<StartStoryBuilderSessionUseCase>((ref) {
      return StartStoryBuilderSessionUseCase(
        sessionRepository: ref.watch(storyBuilderSessionRepositoryProvider),
        eventBus: ref.watch(eventBusProvider),
      );
    });

final presentStoryBuilderPromptUseCaseProvider =
    Provider<PresentStoryBuilderPromptUseCase>((ref) {
      return PresentStoryBuilderPromptUseCase(
        sessionRepository: ref.watch(storyBuilderSessionRepositoryProvider),
        eventBus: ref.watch(eventBusProvider),
      );
    });

final answerStoryBuilderPromptUseCaseProvider =
    Provider<AnswerStoryBuilderPromptUseCase>((ref) {
      return AnswerStoryBuilderPromptUseCase(
        sessionRepository: ref.watch(storyBuilderSessionRepositoryProvider),
        eventBus: ref.watch(eventBusProvider),
      );
    });

final skipStoryBuilderPromptUseCaseProvider =
    Provider<SkipStoryBuilderPromptUseCase>((ref) {
      return SkipStoryBuilderPromptUseCase(
        sessionRepository: ref.watch(storyBuilderSessionRepositoryProvider),
        eventBus: ref.watch(eventBusProvider),
      );
    });

final editStoryBuilderResponseUseCaseProvider =
    Provider<EditStoryBuilderResponseUseCase>((ref) {
      return EditStoryBuilderResponseUseCase(
        sessionRepository: ref.watch(storyBuilderSessionRepositoryProvider),
        eventBus: ref.watch(eventBusProvider),
      );
    });

final setStoryBuilderIntentUseCaseProvider =
    Provider<SetStoryBuilderIntentUseCase>((ref) {
      return SetStoryBuilderIntentUseCase(
        sessionRepository: ref.watch(storyBuilderSessionRepositoryProvider),
        eventBus: ref.watch(eventBusProvider),
      );
    });

final setStoryBuilderPurposeUseCaseProvider =
    Provider<SetStoryBuilderPurposeUseCase>((ref) {
      return SetStoryBuilderPurposeUseCase(
        sessionRepository: ref.watch(storyBuilderSessionRepositoryProvider),
        eventBus: ref.watch(eventBusProvider),
      );
    });

final setStoryBuilderThemesUseCaseProvider =
    Provider<SetStoryBuilderThemesUseCase>((ref) {
      return SetStoryBuilderThemesUseCase(
        sessionRepository: ref.watch(storyBuilderSessionRepositoryProvider),
        eventBus: ref.watch(eventBusProvider),
      );
    });

final pauseStoryBuilderSessionUseCaseProvider =
    Provider<PauseStoryBuilderSessionUseCase>((ref) {
      return PauseStoryBuilderSessionUseCase(
        sessionRepository: ref.watch(storyBuilderSessionRepositoryProvider),
        eventBus: ref.watch(eventBusProvider),
      );
    });

final resumeStoryBuilderSessionUseCaseProvider =
    Provider<ResumeStoryBuilderSessionUseCase>((ref) {
      return ResumeStoryBuilderSessionUseCase(
        sessionRepository: ref.watch(storyBuilderSessionRepositoryProvider),
        eventBus: ref.watch(eventBusProvider),
      );
    });

final completeStoryBuilderSessionUseCaseProvider =
    Provider<CompleteStoryBuilderSessionUseCase>((ref) {
      return CompleteStoryBuilderSessionUseCase(
        sessionRepository: ref.watch(storyBuilderSessionRepositoryProvider),
        eventBus: ref.watch(eventBusProvider),
      );
    });

final abandonStoryBuilderSessionUseCaseProvider =
    Provider<AbandonStoryBuilderSessionUseCase>((ref) {
      return AbandonStoryBuilderSessionUseCase(
        sessionRepository: ref.watch(storyBuilderSessionRepositoryProvider),
        eventBus: ref.watch(eventBusProvider),
      );
    });

final getStoryBuilderSessionUseCaseProvider =
    Provider<GetStoryBuilderSessionUseCase>((ref) {
      return GetStoryBuilderSessionUseCase(
        sessionRepository: ref.watch(storyBuilderSessionRepositoryProvider),
      );
    });

final advanceStoryBuilderUseCaseProvider =
    Provider<AdvanceStoryBuilderUseCase>((ref) {
      return AdvanceStoryBuilderUseCase(
        sessionRepository: ref.watch(storyBuilderSessionRepositoryProvider),
        questionStrategy: ref.watch(storyBuilderQuestionStrategyProvider),
        eventBus: ref.watch(eventBusProvider),
      );
    });

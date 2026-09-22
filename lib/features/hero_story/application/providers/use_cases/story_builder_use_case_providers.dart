import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/eventing/event_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/ai/story_authoring_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/ai/story_builder_understanding_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_builder_session_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_proposal_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/story_builder/story_builder_question_strategy_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/abandon_story_builder_session_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/advance_story_builder_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/answer_story_builder_prompt_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/build_deterministic_story_structure_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/build_story_proposal_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/shape_story_proposal_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/approve_story_proposal_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/begin_story_proposal_revision_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/edit_story_proposal_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/reject_story_proposal_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/complete_story_builder_session_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/deterministic_story_shaper.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_shaper_port.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/edit_story_builder_response_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/get_story_builder_session_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/list_resumable_story_builder_sessions_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/pause_story_builder_session_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/present_story_builder_prompt_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/resume_story_builder_session_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/set_story_builder_intent_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/set_story_builder_mode_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/set_story_builder_purpose_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/set_story_builder_themes_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/skip_story_builder_prompt_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/start_story_builder_session_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/understand_story_builder_session_use_case.dart';

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

final setStoryBuilderModeUseCaseProvider =
    Provider<SetStoryBuilderModeUseCase>((ref) {
      return SetStoryBuilderModeUseCase(
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

final listResumableStoryBuilderSessionsUseCaseProvider =
    Provider<ListResumableStoryBuilderSessionsUseCase>((ref) {
      return ListResumableStoryBuilderSessionsUseCase(
        sessionRepository: ref.watch(storyBuilderSessionRepositoryProvider),
      );
    });

final advanceStoryBuilderUseCaseProvider =
    Provider<AdvanceStoryBuilderUseCase>((ref) {
      return AdvanceStoryBuilderUseCase(
        sessionRepository: ref.watch(storyBuilderSessionRepositoryProvider),
        strategyResolver: ref.watch(
          storyBuilderQuestionStrategyResolverProvider,
        ),
        eventBus: ref.watch(eventBusProvider),
      );
    });

final buildDeterministicStoryStructureUseCaseProvider =
    Provider<BuildDeterministicStoryStructureUseCase>((ref) {
      return BuildDeterministicStoryStructureUseCase(
        sessionRepository: ref.watch(storyBuilderSessionRepositoryProvider),
      );
    });

final understandStoryBuilderSessionUseCaseProvider =
    Provider<UnderstandStoryBuilderSessionUseCase>((ref) {
      return UnderstandStoryBuilderSessionUseCase(
        sessionRepository: ref.watch(storyBuilderSessionRepositoryProvider),
        understandingPort: ref.watch(storyBuilderUnderstandingPortProvider),
      );
    });

final buildStoryProposalUseCaseProvider =
    Provider<BuildStoryProposalUseCase>((ref) {
      return BuildStoryProposalUseCase(
        sessionRepository: ref.watch(storyBuilderSessionRepositoryProvider),
        proposalRepository: ref.watch(storyProposalRepositoryProvider),
      );
    });

/// Default SB.10 shaper — deterministic, offline, AI-agnostic.
final storyShaperPortProvider = Provider<StoryShaperPort>((ref) {
  return const DeterministicStoryShaper();
});

final shapeStoryProposalUseCaseProvider =
    Provider<ShapeStoryProposalUseCase>((ref) {
      return ShapeStoryProposalUseCase(
        proposalRepository: ref.watch(storyProposalRepositoryProvider),
        sessionRepository: ref.watch(storyBuilderSessionRepositoryProvider),
        resolver: ref.watch(storyShaperStrategyResolverProvider),
      );
    });

final editStoryProposalUseCaseProvider =
    Provider<EditStoryProposalUseCase>((ref) {
      return EditStoryProposalUseCase(
        proposalRepository: ref.watch(storyProposalRepositoryProvider),
        sessionRepository: ref.watch(storyBuilderSessionRepositoryProvider),
      );
    });

final approveStoryProposalUseCaseProvider =
    Provider<ApproveStoryProposalUseCase>((ref) {
      return ApproveStoryProposalUseCase(
        proposalRepository: ref.watch(storyProposalRepositoryProvider),
      );
    });

final rejectStoryProposalUseCaseProvider =
    Provider<RejectStoryProposalUseCase>((ref) {
      return RejectStoryProposalUseCase(
        proposalRepository: ref.watch(storyProposalRepositoryProvider),
      );
    });

final beginStoryProposalRevisionUseCaseProvider =
    Provider<BeginStoryProposalRevisionUseCase>((ref) {
      return BeginStoryProposalRevisionUseCase(
        proposalRepository: ref.watch(storyProposalRepositoryProvider),
      );
    });

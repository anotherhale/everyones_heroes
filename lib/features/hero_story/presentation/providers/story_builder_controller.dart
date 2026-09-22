import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/advance_story_builder_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/answer_story_builder_prompt_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/approve_story_proposal_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/begin_story_proposal_revision_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/build_story_proposal_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/edit_story_builder_response_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/edit_story_proposal_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/reject_story_proposal_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/set_story_builder_mode_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/shape_story_proposal_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/skip_story_builder_prompt_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/start_story_builder_session_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/story_builder_session_id_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/advance_story_builder_result.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_proposal_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/story_builder_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_mode.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_session_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_derivation_kind.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_shaper_mode.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/deterministic_story_builder_catalog.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_intent.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_prompt.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_response.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal_section_edit.dart';

enum StoryBuilderUiPhase {
  loading,
  thinking,
  questioning,
  completed,
  proposalPreview,
  error,
  coachUnavailable,
  authoringUnavailable,
}


@immutable
final class StoryBuilderUiState {
  const StoryBuilderUiState({
    required this.phase,
    this.sessionId,
    this.mode = StoryBuilderMode.guided,
    this.prompt,
    this.promptIndex = 0,
    this.draftText = '',
    this.existingResponse,
    this.totalQuestions = 0,
    this.errorMessage,
    this.isBusy = false,
    this.proposal,
    this.originalProposal,
    this.showingOriginalProposal = false,
  });

  final StoryBuilderUiPhase phase;
  final StoryBuilderSessionId? sessionId;
  final StoryBuilderMode mode;
  final StoryBuilderPrompt? prompt;
  final int promptIndex;
  final String draftText;
  final StoryBuilderResponse? existingResponse;
  final int totalQuestions;
  final String? errorMessage;
  final bool isBusy;
  final StoryProposal? proposal;

  /// Pre-AI proposal retained for compare / recovery (SB.11).
  final StoryProposal? originalProposal;

  /// When true, review UI shows [originalProposal] instead of AI proposal.
  final bool showingOriginalProposal;

  int get displayStep => promptIndex + 1;

  bool get isAiMode => mode == StoryBuilderMode.ai;

  bool get canGoBack =>
      promptIndex > 0 && phase == StoryBuilderUiPhase.questioning;

  bool get canFinishEarly =>
      isAiMode &&
      (phase == StoryBuilderUiPhase.questioning ||
          phase == StoryBuilderUiPhase.coachUnavailable) &&
      promptIndex > 0;

  bool get isAiAssistedProposal =>
      proposal?.provenance.derivationKind ==
      StoryProposalDerivationKind.aiShaped;

  bool get canImproveWithAi =>
      phase == StoryBuilderUiPhase.proposalPreview &&
      proposal != null &&
      !isAiAssistedProposal;

  bool get canCompareProposals =>
      originalProposal != null && proposal != null && isAiAssistedProposal;

  StoryProposal? get displayedProposal {
    if (showingOriginalProposal && originalProposal != null) {
      return originalProposal;
    }
    return proposal;
  }

  StoryBuilderUiState copyWith({
    StoryBuilderUiPhase? phase,
    StoryBuilderSessionId? sessionId,
    StoryBuilderMode? mode,
    StoryBuilderPrompt? prompt,
    bool clearPrompt = false,
    int? promptIndex,
    String? draftText,
    StoryBuilderResponse? existingResponse,
    bool clearExistingResponse = false,
    int? totalQuestions,
    String? errorMessage,
    bool clearError = false,
    bool? isBusy,
    StoryProposal? proposal,
    bool clearProposal = false,
    StoryProposal? originalProposal,
    bool clearOriginalProposal = false,
    bool? showingOriginalProposal,
  }) {
    return StoryBuilderUiState(
      phase: phase ?? this.phase,
      sessionId: sessionId ?? this.sessionId,
      mode: mode ?? this.mode,
      prompt: clearPrompt ? null : (prompt ?? this.prompt),
      promptIndex: promptIndex ?? this.promptIndex,
      draftText: draftText ?? this.draftText,
      existingResponse: clearExistingResponse
          ? null
          : (existingResponse ?? this.existingResponse),
      totalQuestions: totalQuestions ?? this.totalQuestions,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isBusy: isBusy ?? this.isBusy,
      proposal: clearProposal ? null : (proposal ?? this.proposal),
      originalProposal: clearOriginalProposal
          ? null
          : (originalProposal ?? this.originalProposal),
      showingOriginalProposal:
          showingOriginalProposal ?? this.showingOriginalProposal,
    );
  }
}

final storyBuilderControllerProvider =
    NotifierProvider.autoDispose<StoryBuilderController, StoryBuilderUiState>(
      StoryBuilderController.new,
    );

final class StoryBuilderController extends Notifier<StoryBuilderUiState> {
  @override
  StoryBuilderUiState build() {
    ref.keepAlive();
    return const StoryBuilderUiState(
      phase: StoryBuilderUiPhase.loading,
      totalQuestions: 11,
    );
  }

  Future<void> startNewSession({
    StoryBuilderMode mode = StoryBuilderMode.guided,
    StoryBuilderIntent? intent,
  }) async {
    state = state.copyWith(
      phase: StoryBuilderUiPhase.loading,
      mode: mode,
      isBusy: true,
      clearError: true,
    );
    try {
      final hero = await ref.read(ensureActiveLocalHeroProvider.future);
      final sessionId = StoryBuilderSessionId.generate();
      final started = await ref.read(startStoryBuilderSessionUseCaseProvider).execute(
            StartStoryBuilderSessionRequest(
              sessionId: sessionId,
              heroId: hero.id,
              mode: mode,
              intent: intent,
            ),
          );
      if (started is Failure) {
        state = state.copyWith(
          phase: StoryBuilderUiPhase.error,
          errorMessage: (started as Failure).error,
          isBusy: false,
        );
        return;
      }
      state = state.copyWith(sessionId: sessionId, mode: mode, isBusy: false);
      await _advance();
    } catch (e) {
      state = state.copyWith(
        phase: StoryBuilderUiPhase.error,
        errorMessage: '$e',
        isBusy: false,
      );
    }
  }

  Future<void> resumeSession(StoryBuilderSessionId sessionId) async {
    state = state.copyWith(
      phase: StoryBuilderUiPhase.loading,
      sessionId: sessionId,
      isBusy: true,
      clearError: true,
    );
    final loaded = await ref.read(getStoryBuilderSessionUseCaseProvider).execute(
          StoryBuilderSessionIdRequest(sessionId: sessionId),
        );
    if (loaded is Failure) {
      state = state.copyWith(
        phase: StoryBuilderUiPhase.error,
        errorMessage: (loaded as Failure).error,
        isBusy: false,
      );
      return;
    }
    final session = (loaded as Success<StoryBuilderSession>).value;
    state = state.copyWith(mode: session.mode);
    if (session.status == StoryBuilderSessionStatus.completed) {
      final resumedProposal = await _loadLatestProposal(sessionId);
      if (resumedProposal != null) {
        state = state.copyWith(
          phase: StoryBuilderUiPhase.proposalPreview,
          proposal: resumedProposal,
          isBusy: false,
          clearPrompt: true,
          clearOriginalProposal: true,
          showingOriginalProposal: false,
        );
        return;
      }
      state = state.copyWith(
        phase: StoryBuilderUiPhase.completed,
        isBusy: false,
        clearPrompt: true,
      );
      return;
    }
    if (session.status == StoryBuilderSessionStatus.abandoned) {
      state = state.copyWith(
        phase: StoryBuilderUiPhase.error,
        errorMessage: 'This Story Builder session was abandoned.',
        isBusy: false,
      );
      return;
    }
    if (session.status == StoryBuilderSessionStatus.paused) {
      await ref.read(resumeStoryBuilderSessionUseCaseProvider).execute(
            StoryBuilderSessionIdRequest(sessionId: sessionId),
          );
    }
    state = state.copyWith(isBusy: false);
    await _advance();
  }

  Future<void> updateDraft(String text) async {
    state = state.copyWith(draftText: text);
  }

  Future<void> continueForward() async {
    if (state.isBusy) {
      return;
    }
    final prompt = state.prompt;
    final sessionId = state.sessionId;
    if (prompt == null || sessionId == null) {
      return;
    }

    if (state.existingResponse == null && state.draftText.trim().isEmpty) {
      await skipCurrent();
      return;
    }

    state = state.copyWith(isBusy: true, clearError: true);

    final existing = state.existingResponse;
    if (existing != null && !existing.skipped) {
      if (state.draftText != existing.text) {
        final edited = await ref.read(editStoryBuilderResponseUseCaseProvider).execute(
              EditStoryBuilderResponseRequest(
                sessionId: sessionId,
                responseId: existing.id,
                text: state.draftText,
              ),
            );
        if (edited is Failure) {
          state = state.copyWith(
            isBusy: false,
            errorMessage: (edited as Failure).error,
          );
          return;
        }
      }
      state = state.copyWith(isBusy: false);
      await _showNextOrAdvance();
      return;
    } else if (existing != null && existing.skipped) {
      state = state.copyWith(isBusy: false);
      await _showNextOrAdvance();
      return;
    } else {
      // Persist Hero answer before requesting the next AI question.
      final answered = await ref.read(answerStoryBuilderPromptUseCaseProvider).execute(
            AnswerStoryBuilderPromptRequest(
              sessionId: sessionId,
              responseId: StoryBuilderResponseId.generate(),
              promptId: prompt.id,
              text: state.draftText,
            ),
          );
      if (answered is Failure) {
        state = state.copyWith(
          isBusy: false,
          errorMessage: (answered as Failure).error,
        );
        return;
      }
    }

    state = state.copyWith(isBusy: false);
    await _advance();
  }

  Future<void> skipCurrent() async {
    if (state.isBusy) {
      return;
    }
    final prompt = state.prompt;
    final sessionId = state.sessionId;
    if (prompt == null || sessionId == null) {
      return;
    }
    if (state.existingResponse != null) {
      await _showNextOrAdvance();
      return;
    }
    state = state.copyWith(isBusy: true, clearError: true);
    final skipped = await ref.read(skipStoryBuilderPromptUseCaseProvider).execute(
          SkipStoryBuilderPromptRequest(
            sessionId: sessionId,
            responseId: StoryBuilderResponseId.generate(),
            promptId: prompt.id,
          ),
        );
    if (skipped is Failure) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: (skipped as Failure).error,
      );
      return;
    }
    state = state.copyWith(isBusy: false);
    await _advance();
  }

  Future<void> goBack() async {
    if (!state.canGoBack || state.sessionId == null || state.isBusy) {
      return;
    }
    final previousIndex = state.promptIndex - 1;
    await _showPromptAtIndex(previousIndex);
  }

  Future<void> pause() async {
    final sessionId = state.sessionId;
    if (sessionId == null) {
      return;
    }
    await ref.read(pauseStoryBuilderSessionUseCaseProvider).execute(
          StoryBuilderSessionIdRequest(sessionId: sessionId),
        );
  }

  /// Hero-driven completion for AI mode (does not wait for coach).
  Future<void> finishSession() async {
    final sessionId = state.sessionId;
    if (sessionId == null || state.isBusy) {
      return;
    }
    state = state.copyWith(isBusy: true, clearError: true);
    final completed = await ref.read(completeStoryBuilderSessionUseCaseProvider).execute(
          StoryBuilderSessionIdRequest(sessionId: sessionId),
        );
    if (completed is Failure) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: (completed as Failure).error,
      );
      return;
    }
    state = state.copyWith(
      phase: StoryBuilderUiPhase.completed,
      clearPrompt: true,
      clearExistingResponse: true,
      draftText: '',
      isBusy: false,
    );
  }

  Future<void> retryCoach() async {
    await _advance();
  }

  /// Explicit Hero decision to continue with Guided after AI failure.
  Future<void> continueWithGuidedBuilder() async {
    final sessionId = state.sessionId;
    if (sessionId == null || state.isBusy) {
      return;
    }
    state = state.copyWith(isBusy: true, clearError: true);
    final switched = await ref.read(setStoryBuilderModeUseCaseProvider).execute(
          SetStoryBuilderModeRequest(
            sessionId: sessionId,
            mode: StoryBuilderMode.guided,
          ),
        );
    if (switched is Failure) {
      state = state.copyWith(
        phase: StoryBuilderUiPhase.coachUnavailable,
        errorMessage: (switched as Failure).error,
        isBusy: false,
      );
      return;
    }
    state = state.copyWith(mode: StoryBuilderMode.guided, isBusy: false);
    await _advance();
  }

  Future<void> _showNextOrAdvance() async {
    if (state.isAiMode) {
      final sessionId = state.sessionId;
      if (sessionId == null) {
        return;
      }
      final loaded =
          await ref.read(getStoryBuilderSessionUseCaseProvider).execute(
                StoryBuilderSessionIdRequest(sessionId: sessionId),
              );
      if (loaded is! Success<StoryBuilderSession>) {
        await _advance();
        return;
      }
      final session = loaded.value;
      final nextIndex = state.promptIndex + 1;
      if (nextIndex < session.prompts.length) {
        await _bindPrompt(session, session.prompts[nextIndex], nextIndex);
        return;
      }
      await _advance();
      return;
    }
    final nextIndex = state.promptIndex + 1;
    if (nextIndex < DeterministicStoryBuilderCatalog.length) {
      await _showPromptAtIndex(nextIndex);
    } else {
      await _advance();
    }
  }

  Future<void> _advance() async {
    final sessionId = state.sessionId;
    if (sessionId == null) {
      return;
    }
    state = state.copyWith(
      phase: state.isAiMode
          ? StoryBuilderUiPhase.thinking
          : StoryBuilderUiPhase.loading,
      isBusy: true,
      clearError: true,
    );
    final result = await ref.read(advanceStoryBuilderUseCaseProvider).execute(
          AdvanceStoryBuilderRequest(sessionId: sessionId),
        );
    if (result is Failure) {
      final message = (result as Failure).error;
      state = state.copyWith(
        phase: state.isAiMode
            ? StoryBuilderUiPhase.coachUnavailable
            : StoryBuilderUiPhase.error,
        errorMessage: message,
        isBusy: false,
      );
      return;
    }
    final advanced = (result as Success<AdvanceStoryBuilderResult>).value;
    state = state.copyWith(mode: advanced.session.mode);
    if (advanced.questioningComplete) {
      state = state.copyWith(
        phase: StoryBuilderUiPhase.completed,
        clearPrompt: true,
        clearExistingResponse: true,
        draftText: '',
        isBusy: false,
      );
      return;
    }
    final prompt = advanced.currentPrompt!;
    final index = _indexOfPrompt(advanced.session, prompt);
    await _bindPrompt(advanced.session, prompt, index);
  }

  Future<void> _showPromptAtIndex(int index) async {
    final sessionId = state.sessionId;
    if (sessionId == null) {
      return;
    }
    final loaded = await ref.read(getStoryBuilderSessionUseCaseProvider).execute(
          StoryBuilderSessionIdRequest(sessionId: sessionId),
        );
    if (loaded is! Success<StoryBuilderSession>) {
      return;
    }
    final session = loaded.value;
    if (session.mode == StoryBuilderMode.guided) {
      if (index < 0 || index >= DeterministicStoryBuilderCatalog.length) {
        return;
      }
      final prompt = DeterministicStoryBuilderCatalog.prompts[index];
      await _bindPrompt(session, prompt, index);
      return;
    }
    if (index < 0 || index >= session.prompts.length) {
      return;
    }
    await _bindPrompt(session, session.prompts[index], index);
  }

  int _indexOfPrompt(StoryBuilderSession session, StoryBuilderPrompt prompt) {
    if (session.mode == StoryBuilderMode.guided) {
      return DeterministicStoryBuilderCatalog.indexOf(prompt.id) ?? 0;
    }
    for (var i = 0; i < session.prompts.length; i++) {
      if (session.prompts[i].id == prompt.id) {
        return i;
      }
    }
    return session.prompts.isEmpty ? 0 : session.prompts.length - 1;
  }

  Future<void> _bindPrompt(
    StoryBuilderSession session,
    StoryBuilderPrompt prompt,
    int index,
  ) async {
    StoryBuilderResponse? existing;
    for (final response in session.responses) {
      if (response.promptId == prompt.id) {
        existing = response;
        break;
      }
    }
    final total = session.mode == StoryBuilderMode.guided
        ? DeterministicStoryBuilderCatalog.length
        : (session.prompts.isEmpty ? 1 : session.prompts.length);
    state = state.copyWith(
      phase: StoryBuilderUiPhase.questioning,
      mode: session.mode,
      prompt: prompt,
      promptIndex: index,
      draftText: existing?.text ?? '',
      existingResponse: existing,
      clearExistingResponse: existing == null,
      totalQuestions: total,
      isBusy: false,
      clearError: true,
    );
  }

  /// Builds a Story Proposal then applies deterministic shaping (SB.9 → SB.10).
  ///
  /// UX: Build Story Proposal → shape → Review Story (proposal preview).
  /// Does not automatically invoke AI authoring (SB.11 is explicit).
  Future<void> buildStoryProposal() async {
    final sessionId = state.sessionId;
    if (sessionId == null || state.isBusy) {
      return;
    }
    state = state.copyWith(
      isBusy: true,
      clearError: true,
      clearOriginalProposal: true,
      showingOriginalProposal: false,
    );
    final buildResult =
        await ref.read(buildStoryProposalUseCaseProvider).execute(
              BuildStoryProposalRequest(sessionId: sessionId),
            );
    if (buildResult is Failure) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: (buildResult as Failure).error,
      );
      return;
    }
    final built = (buildResult as Success<StoryProposal>).value;

    final shapeResult =
        await ref.read(shapeStoryProposalUseCaseProvider).execute(
              ShapeStoryProposalRequest(
                proposalId: built.id,
                mode: StoryShaperMode.deterministic,
              ),
            );
    if (shapeResult is Failure) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: (shapeResult as Failure).error,
      );
      return;
    }
    final proposal = (shapeResult as Success<StoryProposal>).value;
    state = state.copyWith(
      phase: StoryBuilderUiPhase.proposalPreview,
      proposal: proposal,
      isBusy: false,
      clearError: true,
      clearOriginalProposal: true,
      showingOriginalProposal: false,
    );
  }

  /// Explicitly invokes AI authoring on the current proposal (SB.11).
  ///
  /// On failure, keeps the existing proposal and enters authoringUnavailable.
  Future<void> improveProposalWithAi() async {
    final current = state.proposal;
    if (current == null || state.isBusy) {
      return;
    }
    state = state.copyWith(isBusy: true, clearError: true);
    final result = await ref.read(shapeStoryProposalUseCaseProvider).execute(
          ShapeStoryProposalRequest(
            proposalId: current.id,
            mode: StoryShaperMode.ai,
          ),
        );
    if (result is Failure) {
      state = state.copyWith(
        phase: StoryBuilderUiPhase.authoringUnavailable,
        isBusy: false,
        errorMessage: (result as Failure).error,
        // Keep current proposal as the recoverable original.
        originalProposal: state.originalProposal ?? current,
        proposal: current,
      );
      return;
    }
    final shaped = (result as Success<StoryProposal>).value;
    state = state.copyWith(
      phase: StoryBuilderUiPhase.proposalPreview,
      originalProposal: state.originalProposal ?? current,
      proposal: shaped,
      showingOriginalProposal: false,
      isBusy: false,
      clearError: true,
    );
  }

  void retryAiAuthoring() {
    state = state.copyWith(
      phase: StoryBuilderUiPhase.proposalPreview,
      clearError: true,
    );
    improveProposalWithAi();
  }

  void continueWithCurrentProposal() {
    final proposal = state.proposal ?? state.originalProposal;
    state = state.copyWith(
      phase: StoryBuilderUiPhase.proposalPreview,
      proposal: proposal,
      clearError: true,
      isBusy: false,
      showingOriginalProposal: false,
    );
  }

  void toggleProposalCompare() {
    if (!state.canCompareProposals) {
      return;
    }
    state = state.copyWith(
      showingOriginalProposal: !state.showingOriginalProposal,
    );
  }

  void leaveProposalPreview() {
    state = state.copyWith(
      phase: StoryBuilderUiPhase.completed,
      clearProposal: true,
      clearOriginalProposal: true,
      showingOriginalProposal: false,
      clearError: true,
    );
  }

  /// Persists Hero edits to the current proposal (SB.12).
  Future<bool> saveProposalEdits({
    String? title,
    bool updateTitle = false,
    bool clearTitle = false,
    String? summary,
    bool updateSummary = false,
    bool clearSummary = false,
    List<StoryProposalSectionEdit> sectionEdits = const [],
  }) async {
    final current = state.proposal;
    if (current == null || state.isBusy) {
      return false;
    }
    state = state.copyWith(isBusy: true, clearError: true);
    final result = await ref.read(editStoryProposalUseCaseProvider).execute(
          EditStoryProposalRequest(
            proposalId: current.id,
            title: title,
            updateTitle: updateTitle,
            clearTitle: clearTitle,
            summary: summary,
            updateSummary: updateSummary,
            clearSummary: clearSummary,
            sectionEdits: sectionEdits,
          ),
        );
    if (result is Failure) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: (result as Failure).error,
      );
      return false;
    }
    final edited = (result as Success<StoryProposal>).value;
    state = state.copyWith(
      phase: StoryBuilderUiPhase.proposalPreview,
      proposal: edited,
      isBusy: false,
      clearError: true,
      showingOriginalProposal: false,
    );
    return true;
  }

  /// Explicit Hero approval — only path to accepted (SB.12).
  Future<bool> approveProposal() async {
    final current = state.proposal;
    if (current == null || state.isBusy) {
      return false;
    }
    state = state.copyWith(isBusy: true, clearError: true);
    final result =
        await ref.read(approveStoryProposalUseCaseProvider).execute(
              ApproveStoryProposalRequest(proposalId: current.id),
            );
    if (result is Failure) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: (result as Failure).error,
      );
      return false;
    }
    final approved = (result as Success<StoryProposal>).value;
    state = state.copyWith(
      phase: StoryBuilderUiPhase.proposalPreview,
      proposal: approved,
      isBusy: false,
      clearError: true,
      showingOriginalProposal: false,
    );
    return true;
  }

  /// Explicit Hero rejection (SB.12). Proposal remains persisted.
  Future<bool> rejectProposal() async {
    final current = state.proposal;
    if (current == null || state.isBusy) {
      return false;
    }
    state = state.copyWith(isBusy: true, clearError: true);
    final result = await ref.read(rejectStoryProposalUseCaseProvider).execute(
          RejectStoryProposalRequest(proposalId: current.id),
        );
    if (result is Failure) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: (result as Failure).error,
      );
      return false;
    }
    final rejected = (result as Success<StoryProposal>).value;
    state = state.copyWith(
      phase: StoryBuilderUiPhase.proposalPreview,
      proposal: rejected,
      isBusy: false,
      clearError: true,
      showingOriginalProposal: false,
    );
    return true;
  }

  /// Invalidates prior approval/rejection so the Hero can edit again.
  Future<bool> beginProposalRevision() async {
    final current = state.proposal;
    if (current == null || state.isBusy) {
      return false;
    }
    if (current.lifecycle != StoryProposalLifecycleStatus.accepted &&
        current.lifecycle != StoryProposalLifecycleStatus.rejected) {
      return true;
    }
    state = state.copyWith(isBusy: true, clearError: true);
    final result =
        await ref.read(beginStoryProposalRevisionUseCaseProvider).execute(
              BeginStoryProposalRevisionRequest(proposalId: current.id),
            );
    if (result is Failure) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: (result as Failure).error,
      );
      return false;
    }
    final revised = (result as Success<StoryProposal>).value;
    state = state.copyWith(
      phase: StoryBuilderUiPhase.proposalPreview,
      proposal: revised,
      isBusy: false,
      clearError: true,
      showingOriginalProposal: false,
    );
    return true;
  }

  Future<StoryProposal?> _loadLatestProposal(
    StoryBuilderSessionId sessionId,
  ) async {
    final proposals = List<StoryProposal>.of(
      await ref
          .read(storyProposalRepositoryProvider)
          .findBySessionId(sessionId),
    );
    if (proposals.isEmpty) {
      return null;
    }
    proposals.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return proposals.first;
  }
}

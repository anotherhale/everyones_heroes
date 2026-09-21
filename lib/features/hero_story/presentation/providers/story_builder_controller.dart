import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/advance_story_builder_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/answer_story_builder_prompt_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/edit_story_builder_response_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/skip_story_builder_prompt_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/start_story_builder_session_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/story_builder_session_id_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/advance_story_builder_result.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/story_builder_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_mode.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_session_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/deterministic_story_builder_catalog.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_prompt.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_response.dart';

enum StoryBuilderUiPhase {
  loading,
  questioning,
  completed,
  error,
}

@immutable
final class StoryBuilderUiState {
  const StoryBuilderUiState({
    required this.phase,
    this.sessionId,
    this.prompt,
    this.catalogIndex = 0,
    this.draftText = '',
    this.existingResponse,
    this.totalQuestions = 0,
    this.errorMessage,
    this.isBusy = false,
  });

  final StoryBuilderUiPhase phase;
  final StoryBuilderSessionId? sessionId;
  final StoryBuilderPrompt? prompt;
  final int catalogIndex;
  final String draftText;
  final StoryBuilderResponse? existingResponse;
  final int totalQuestions;
  final String? errorMessage;
  final bool isBusy;

  int get displayStep => catalogIndex + 1;

  bool get canGoBack => catalogIndex > 0 && phase == StoryBuilderUiPhase.questioning;

  StoryBuilderUiState copyWith({
    StoryBuilderUiPhase? phase,
    StoryBuilderSessionId? sessionId,
    StoryBuilderPrompt? prompt,
    bool clearPrompt = false,
    int? catalogIndex,
    String? draftText,
    StoryBuilderResponse? existingResponse,
    bool clearExistingResponse = false,
    int? totalQuestions,
    String? errorMessage,
    bool clearError = false,
    bool? isBusy,
  }) {
    return StoryBuilderUiState(
      phase: phase ?? this.phase,
      sessionId: sessionId ?? this.sessionId,
      prompt: clearPrompt ? null : (prompt ?? this.prompt),
      catalogIndex: catalogIndex ?? this.catalogIndex,
      draftText: draftText ?? this.draftText,
      existingResponse: clearExistingResponse
          ? null
          : (existingResponse ?? this.existingResponse),
      totalQuestions: totalQuestions ?? this.totalQuestions,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isBusy: isBusy ?? this.isBusy,
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

  Future<void> startNewSession() async {
    state = state.copyWith(
      phase: StoryBuilderUiPhase.loading,
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
              mode: StoryBuilderMode.guided,
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
      state = state.copyWith(sessionId: sessionId, isBusy: false);
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
    if (session.status == StoryBuilderSessionStatus.completed) {
      state = state.copyWith(
        phase: StoryBuilderUiPhase.completed,
        isBusy: false,
        clearPrompt: true,
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
      final nextIndex = state.catalogIndex + 1;
      if (nextIndex < DeterministicStoryBuilderCatalog.length) {
        await _showCatalogIndex(nextIndex);
      } else {
        await _advance();
      }
      return;
    } else if (existing != null && existing.skipped) {
      state = state.copyWith(isBusy: false);
      final nextIndex = state.catalogIndex + 1;
      if (nextIndex < DeterministicStoryBuilderCatalog.length) {
        await _showCatalogIndex(nextIndex);
      } else {
        await _advance();
      }
      return;
    } else {
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
    final prompt = state.prompt;
    final sessionId = state.sessionId;
    if (prompt == null || sessionId == null) {
      return;
    }
    if (state.existingResponse != null) {
      final nextIndex = state.catalogIndex + 1;
      if (nextIndex < DeterministicStoryBuilderCatalog.length) {
        await _showCatalogIndex(nextIndex);
      } else {
        await _advance();
      }
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
    if (!state.canGoBack || state.sessionId == null) {
      return;
    }
    final previousIndex = state.catalogIndex - 1;
    await _showCatalogIndex(previousIndex);
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

  Future<void> _advance() async {
    final sessionId = state.sessionId;
    if (sessionId == null) {
      return;
    }
    state = state.copyWith(isBusy: true, clearError: true);
    final result = await ref.read(advanceStoryBuilderUseCaseProvider).execute(
          AdvanceStoryBuilderRequest(sessionId: sessionId),
        );
    if (result is Failure) {
      state = state.copyWith(
        phase: StoryBuilderUiPhase.error,
        errorMessage: (result as Failure).error,
        isBusy: false,
      );
      return;
    }
    final advanced = (result as Success<AdvanceStoryBuilderResult>).value;
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
    final index = DeterministicStoryBuilderCatalog.indexOf(prompt.id) ?? 0;
    await _bindPrompt(advanced.session, prompt, index);
  }

  Future<void> _showCatalogIndex(int index) async {
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
    final prompt = DeterministicStoryBuilderCatalog.prompts[index];
    await _bindPrompt(session, prompt, index);
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
    state = state.copyWith(
      phase: StoryBuilderUiPhase.questioning,
      prompt: prompt,
      catalogIndex: index,
      draftText: existing?.text ?? '',
      existingResponse: existing,
      clearExistingResponse: existing == null,
      totalQuestions: DeterministicStoryBuilderCatalog.length,
      isBusy: false,
      clearError: true,
    );
  }
}

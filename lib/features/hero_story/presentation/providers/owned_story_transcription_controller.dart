import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/approve_story_representation_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/edit_unapproved_story_representation_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/get_owned_story_transcription_status_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/start_owned_story_transcription_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/update_story_consent_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/approve_story_representation_response.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/owned_story_transcription_status.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/start_owned_story_transcription_response.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/capture_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/transcription_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_transcription_job_status.dart';
import 'package:everyonesheroes/features/hero_story/presentation/models/owned_story_labels.dart';
import 'package:everyonesheroes/features/hero_story/presentation/models/owned_story_transcription_view_model.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/owned_story_providers.dart';

@immutable
final class OwnedStoryTranscriptionUiState {
  const OwnedStoryTranscriptionUiState({
    this.isLoading = true,
    this.isBusy = false,
    this.model,
    this.errorMessage,
  });

  final bool isLoading;
  final bool isBusy;
  final OwnedStoryTranscriptionViewModel? model;
  final String? errorMessage;

  OwnedStoryTranscriptionUiState copyWith({
    bool? isLoading,
    bool? isBusy,
    OwnedStoryTranscriptionViewModel? model,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OwnedStoryTranscriptionUiState(
      isLoading: isLoading ?? this.isLoading,
      isBusy: isBusy ?? this.isBusy,
      model: model ?? this.model,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final ownedStoryTranscriptionProvider = NotifierProvider.autoDispose
    .family<OwnedStoryTranscriptionController, OwnedStoryTranscriptionUiState,
        String>(
  OwnedStoryTranscriptionController.new,
);

/// Owner Story Detail transcription actions (HS.11).
final class OwnedStoryTranscriptionController
    extends Notifier<OwnedStoryTranscriptionUiState> {
  OwnedStoryTranscriptionController(this.storyIdValue);

  final String storyIdValue;

  @override
  OwnedStoryTranscriptionUiState build() {
    Future.microtask(refresh);
    return const OwnedStoryTranscriptionUiState();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final hero = await ref.read(ensureActiveLocalHeroProvider.future);
      final result = await ref
          .read(getOwnedStoryTranscriptionStatusUseCaseProvider)
          .execute(
            GetOwnedStoryTranscriptionStatusRequest(
              storyId: StoryId(storyIdValue),
              ownerHeroId: hero.id,
            ),
          );
      if (result is Failure<OwnedStoryTranscriptionStatus>) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.error,
        );
        return;
      }
      final model = OwnedStoryTranscriptionViewModel.fromStatus(
        (result as Success<OwnedStoryTranscriptionStatus>).value,
      );
      state = state.copyWith(
        isLoading: false,
        model: model,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<String?> startTranscription({bool isRetry = false}) async {
    final hero = await ref.read(ensureActiveLocalHeroProvider.future);
    final current = state.model;
    state = state.copyWith(
      isBusy: true,
      clearError: true,
      model: current == null
          ? OwnedStoryTranscriptionViewModel(
              storyId: StoryId(storyIdValue),
              status: StoryTranscriptionJobStatus.inProgress,
              statusLabel: OwnedStoryLabels.transcriptionStatusLabel(
                StoryTranscriptionJobStatus.inProgress,
              ),
              hasAiProcessingConsent: true,
              canStart: false,
              canRetry: false,
              showProcessing: true,
              showTranscript: false,
            )
          : OwnedStoryTranscriptionViewModel(
              storyId: current.storyId,
              status: StoryTranscriptionJobStatus.inProgress,
              statusLabel: OwnedStoryLabels.transcriptionStatusLabel(
                StoryTranscriptionJobStatus.inProgress,
              ),
              hasAiProcessingConsent: current.hasAiProcessingConsent,
              canStart: false,
              canRetry: false,
              showProcessing: true,
              showTranscript: false,
              sourceRepresentationId: current.sourceRepresentationId,
              transcriptRepresentationId: current.transcriptRepresentationId,
              transcriptText: current.transcriptText,
              transcriptIsApproved: current.transcriptIsApproved,
            ),
    );

    final result = await ref
        .read(startOwnedStoryTranscriptionUseCaseProvider)
        .execute(
          StartOwnedStoryTranscriptionRequest(
            storyId: StoryId(storyIdValue),
            ownerHeroId: hero.id,
            isRetry: isRetry,
          ),
        );

    state = state.copyWith(isBusy: false);
    if (result is Failure<StartOwnedStoryTranscriptionResponse>) {
      await refresh();
      ref.invalidate(ownedStoryDetailProvider(storyIdValue));
      return result.error;
    }

    await refresh();
    ref.invalidate(ownedStoryDetailProvider(storyIdValue));
    ref.invalidate(ownedStoriesProvider);
    return null;
  }

  Future<String?> grantAiProcessingConsent() async {
    state = state.copyWith(isBusy: true, clearError: true);
    final result = await ref.read(updateStoryConsentUseCaseProvider).execute(
          UpdateStoryConsentRequest(
            storyId: StoryId(storyIdValue),
            grantProcessing: true,
            grantAiTransformation: true,
          ),
        );
    state = state.copyWith(isBusy: false);
    if (result is Failure<Story>) {
      return result.error;
    }
    await refresh();
    ref.invalidate(ownedStoryDetailProvider(storyIdValue));
    return null;
  }

  Future<String?> saveTranscriptEdit(String text) async {
    final transcriptId = state.model?.transcriptRepresentationId;
    if (transcriptId == null) {
      return 'No transcript available to edit.';
    }
    state = state.copyWith(isBusy: true, clearError: true);
    final result = await ref
        .read(editUnapprovedStoryRepresentationUseCaseProvider)
        .execute(
          EditUnapprovedStoryRepresentationRequest(
            storyId: StoryId(storyIdValue),
            representationId: transcriptId,
            textContent: text,
          ),
        );
    state = state.copyWith(isBusy: false);
    if (result is Failure<Story>) {
      return result.error;
    }
    await refresh();
    ref.invalidate(ownedStoryDetailProvider(storyIdValue));
    return null;
  }

  Future<String?> approveTranscript() async {
    final transcriptId = state.model?.transcriptRepresentationId;
    if (transcriptId == null) {
      return 'No transcript available to approve.';
    }
    state = state.copyWith(isBusy: true, clearError: true);
    final result = await ref
        .read(approveStoryRepresentationUseCaseProvider)
        .execute(
          ApproveStoryRepresentationRequest(
            storyId: StoryId(storyIdValue),
            representationId: transcriptId,
            requestId: 'approve-${transcriptId.value}',
          ),
        );
    state = state.copyWith(isBusy: false);
    if (result is Failure<ApproveStoryRepresentationResponse>) {
      return result.error;
    }
    await refresh();
    ref.invalidate(ownedStoryDetailProvider(storyIdValue));
    return null;
  }
}

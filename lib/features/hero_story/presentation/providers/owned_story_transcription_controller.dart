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
import 'package:everyonesheroes/features/hero_story/presentation/models/owned_story_transcription_view_model.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/owned_story_providers.dart';

final ownedStoryTranscriptionProvider = AsyncNotifierProvider.autoDispose
    .family<OwnedStoryTranscriptionController, OwnedStoryTranscriptionViewModel,
        String>(OwnedStoryTranscriptionController.new);

class OwnedStoryTranscriptionController extends AutoDisposeFamilyAsyncNotifier<
    OwnedStoryTranscriptionViewModel, String> {
  @override
  Future<OwnedStoryTranscriptionViewModel> build(String storyIdValue) async {
    return _load(storyIdValue);
  }

  Future<OwnedStoryTranscriptionViewModel> _load(String storyIdValue) async {
    final hero = await ref.watch(ensureActiveLocalHeroProvider.future);
    final result = await ref
        .watch(getOwnedStoryTranscriptionStatusUseCaseProvider)
        .execute(
          GetOwnedStoryTranscriptionStatusRequest(
            storyId: StoryId(storyIdValue),
            ownerHeroId: hero.id,
          ),
        );
    if (result is Failure<OwnedStoryTranscriptionStatus>) {
      throw Exception(result.error);
    }
    return OwnedStoryTranscriptionViewModel.fromStatus(
      (result as Success<OwnedStoryTranscriptionStatus>).value,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(arg));
  }

  Future<String?> startTranscription({bool isRetry = false}) async {
    final hero = await ref.read(ensureActiveLocalHeroProvider.future);
    state = AsyncData(
      (state.value ??
              OwnedStoryTranscriptionViewModel(
                storyId: StoryId(arg),
                status: StoryTranscriptionJobStatus.inProgress,
                statusLabel: 'Transcribing…',
                hasAiProcessingConsent: true,
                canStart: false,
                canRetry: false,
                showProcessing: true,
                showTranscript: false,
              ))
          .copyWithInProgress(),
    );

    final result = await ref
        .read(startOwnedStoryTranscriptionUseCaseProvider)
        .execute(
          StartOwnedStoryTranscriptionRequest(
            storyId: StoryId(arg),
            ownerHeroId: hero.id,
            isRetry: isRetry,
          ),
        );

    if (result is Failure<StartOwnedStoryTranscriptionResponse>) {
      await refresh();
      ref.invalidate(ownedStoryDetailProvider(arg));
      return result.error;
    }

    await refresh();
    ref.invalidate(ownedStoryDetailProvider(arg));
    ref.invalidate(ownedStoriesProvider);
    return null;
  }

  Future<String?> grantAiProcessingConsent() async {
    final result = await ref.read(updateStoryConsentUseCaseProvider).execute(
          UpdateStoryConsentRequest(
            storyId: StoryId(arg),
            grantProcessing: true,
            grantAiTransformation: true,
          ),
        );
    if (result is Failure<Story>) {
      return result.error;
    }
    await refresh();
    ref.invalidate(ownedStoryDetailProvider(arg));
    return null;
  }

  Future<String?> saveTranscriptEdit(String text) async {
    final current = state.value;
    final transcriptId = current?.transcriptRepresentationId;
    if (transcriptId == null) {
      return 'No transcript available to edit.';
    }
    final result = await ref
        .read(editUnapprovedStoryRepresentationUseCaseProvider)
        .execute(
          EditUnapprovedStoryRepresentationRequest(
            storyId: StoryId(arg),
            representationId: transcriptId,
            textContent: text,
          ),
        );
    if (result is Failure<Story>) {
      return result.error;
    }
    await refresh();
    ref.invalidate(ownedStoryDetailProvider(arg));
    return null;
  }

  Future<String?> approveTranscript() async {
    final current = state.value;
    final transcriptId = current?.transcriptRepresentationId;
    if (transcriptId == null) {
      return 'No transcript available to approve.';
    }
    final result = await ref
        .read(approveStoryRepresentationUseCaseProvider)
        .execute(
          ApproveStoryRepresentationRequest(
            storyId: StoryId(arg),
            representationId: transcriptId,
            requestId: 'approve-${transcriptId.value}',
          ),
        );
    if (result is Failure<ApproveStoryRepresentationResponse>) {
      return result.error;
    }
    await refresh();
    ref.invalidate(ownedStoryDetailProvider(arg));
    return null;
  }
}

extension on OwnedStoryTranscriptionViewModel {
  OwnedStoryTranscriptionViewModel copyWithInProgress() {
    return OwnedStoryTranscriptionViewModel(
      storyId: storyId,
      status: StoryTranscriptionJobStatus.inProgress,
      statusLabel: 'Transcribing…',
      hasAiProcessingConsent: hasAiProcessingConsent,
      canStart: false,
      canRetry: false,
      showProcessing: true,
      showTranscript: false,
      sourceRepresentationId: sourceRepresentationId,
      transcriptRepresentationId: transcriptRepresentationId,
      transcriptText: transcriptText,
      transcriptIsApproved: transcriptIsApproved,
      errorMessage: null,
    );
  }
}

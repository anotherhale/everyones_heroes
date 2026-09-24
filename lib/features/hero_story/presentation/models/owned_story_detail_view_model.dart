import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/owned_story_detail.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_visibility.dart';
import 'package:everyonesheroes/features/hero_story/presentation/models/owned_story_labels.dart';

/// Owner Story detail presentation model (HS.10 / HS.FG.1).
final class OwnedStoryDetailViewModel {
  const OwnedStoryDetailViewModel({
    required this.storyId,
    required this.heroId,
    required this.title,
    required this.recordedLabel,
    required this.lifecycleStatus,
    required this.lifecycleLabel,
    required this.visibility,
    required this.privacyLabel,
    required this.isRecorded,
    required this.isProcessingApproved,
    required this.isPublicationApproved,
    required this.isAiTransformationApproved,
    required this.isVoiceRenderingApproved,
    required this.hasProvisionalNarrative,
    required this.originalLanguage,
    required this.canArchive,
    required this.canSubmit,
    required this.canApprove,
    required this.canPublish,
    this.durationLabel,
    this.primaryOriginalAudioId,
  });

  final StoryId storyId;
  final HeroId heroId;
  final String title;
  final String recordedLabel;
  final String? durationLabel;
  final StoryLifecycleStatus lifecycleStatus;
  final String lifecycleLabel;
  final StoryVisibility visibility;
  final String privacyLabel;
  final bool isRecorded;
  final bool isProcessingApproved;
  final bool isPublicationApproved;
  final bool isAiTransformationApproved;
  final bool isVoiceRenderingApproved;
  final bool hasProvisionalNarrative;
  final LanguageCode originalLanguage;
  final StoryRepresentationId? primaryOriginalAudioId;
  final bool canArchive;

  /// Owner may submit a draft Story (consent granted by the submit action).
  final bool canSubmit;

  /// Owner may approve a submitted / in-review Story (existing model allows
  /// self-approval; no separate moderator role).
  final bool canApprove;

  /// Owner may publish an approved Story (visibility + publication consent
  /// applied by the publish action when needed).
  final bool canPublish;

  factory OwnedStoryDetailViewModel.fromDetail(OwnedStoryDetail detail) {
    final status = detail.lifecycleStatus;
    final provisional = detail.hasProvisionalNarrative;
    return OwnedStoryDetailViewModel(
      storyId: detail.storyId,
      heroId: detail.heroId,
      title: OwnedStoryLabels.displayTitle(
        detail.title,
        createdAt: detail.createdAt,
      ),
      recordedLabel: OwnedStoryLabels.formatDate(detail.createdAt),
      durationLabel: detail.primaryOriginalAudioDuration == null
          ? null
          : OwnedStoryLabels.formatDuration(
              detail.primaryOriginalAudioDuration!,
            ),
      lifecycleStatus: status,
      lifecycleLabel: OwnedStoryLabels.lifecycleLabel(status),
      visibility: detail.visibility,
      privacyLabel: OwnedStoryLabels.privacyLabel(detail.visibility),
      isRecorded: detail.isRecorded,
      isProcessingApproved: detail.isProcessingApproved,
      isPublicationApproved: detail.isPublicationApproved,
      isAiTransformationApproved: detail.isAiTransformationApproved,
      isVoiceRenderingApproved: detail.isVoiceRenderingApproved,
      hasProvisionalNarrative: provisional,
      originalLanguage: detail.originalLanguage,
      primaryOriginalAudioId: detail.primaryOriginalAudioId,
      canArchive:
          status != StoryLifecycleStatus.archived &&
          status != StoryLifecycleStatus.removed,
      canSubmit: status == StoryLifecycleStatus.draft,
      canApprove: !provisional &&
          (status == StoryLifecycleStatus.processing ||
              status == StoryLifecycleStatus.review),
      canPublish: status == StoryLifecycleStatus.approved && !provisional,
    );
  }
}

import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/owned_story_detail.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/presentation/models/owned_story_labels.dart';

/// Owner Story detail presentation model (HS.10).
final class OwnedStoryDetailViewModel {
  const OwnedStoryDetailViewModel({
    required this.storyId,
    required this.heroId,
    required this.title,
    required this.recordedLabel,
    required this.lifecycleLabel,
    required this.privacyLabel,
    required this.isRecorded,
    required this.isProcessingApproved,
    required this.isPublicationApproved,
    required this.isAiTransformationApproved,
    required this.hasProvisionalNarrative,
    required this.originalLanguage,
    required this.canArchive,
    this.durationLabel,
    this.primaryOriginalAudioId,
  });

  final StoryId storyId;
  final HeroId heroId;
  final String title;
  final String recordedLabel;
  final String? durationLabel;
  final String lifecycleLabel;
  final String privacyLabel;
  final bool isRecorded;
  final bool isProcessingApproved;
  final bool isPublicationApproved;
  final bool isAiTransformationApproved;
  final bool hasProvisionalNarrative;
  final LanguageCode originalLanguage;
  final StoryRepresentationId? primaryOriginalAudioId;
  final bool canArchive;

  factory OwnedStoryDetailViewModel.fromDetail(OwnedStoryDetail detail) {
    final status = detail.lifecycleStatus;
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
      lifecycleLabel: OwnedStoryLabels.lifecycleLabel(status),
      privacyLabel: OwnedStoryLabels.privacyLabel(detail.visibility),
      isRecorded: detail.isRecorded,
      isProcessingApproved: detail.isProcessingApproved,
      isPublicationApproved: detail.isPublicationApproved,
      isAiTransformationApproved: detail.isAiTransformationApproved,
      hasProvisionalNarrative: detail.hasProvisionalNarrative,
      originalLanguage: detail.originalLanguage,
      primaryOriginalAudioId: detail.primaryOriginalAudioId,
      canArchive:
          status != StoryLifecycleStatus.archived &&
          status != StoryLifecycleStatus.removed,
    );
  }
}

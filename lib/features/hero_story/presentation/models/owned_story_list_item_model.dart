import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/owned_story_summary.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_visibility.dart';
import 'package:everyonesheroes/features/hero_story/presentation/models/owned_story_labels.dart';

/// Presentation model for My Stories list items (HS.10).
final class OwnedStoryListItemModel {
  const OwnedStoryListItemModel({
    required this.storyId,
    required this.title,
    required this.recordedLabel,
    required this.createdAt,
    required this.lifecycleLabel,
    required this.privacyLabel,
    required this.hasMedia,
    this.durationLabel,
    this.primaryRepresentationId,
  });

  final StoryId storyId;
  final String title;
  final String recordedLabel;
  final DateTime createdAt;
  final String? durationLabel;
  final String lifecycleLabel;
  final String privacyLabel;
  final bool hasMedia;
  final StoryRepresentationId? primaryRepresentationId;

  factory OwnedStoryListItemModel.fromSummary(OwnedStorySummary summary) {
    return OwnedStoryListItemModel(
      storyId: summary.storyId,
      title: OwnedStoryLabels.displayTitle(
        summary.title,
        createdAt: summary.createdAt,
      ),
      recordedLabel: OwnedStoryLabels.formatDate(summary.createdAt),
      createdAt: summary.createdAt,
      durationLabel: summary.duration == null
          ? null
          : OwnedStoryLabels.formatDuration(summary.duration!),
      lifecycleLabel: OwnedStoryLabels.lifecycleLabel(summary.lifecycleStatus),
      privacyLabel: OwnedStoryLabels.privacyLabel(summary.visibility),
      hasMedia: summary.hasMedia,
      primaryRepresentationId: summary.primaryRepresentationId,
    );
  }
}

extension OwnedStoryListItemLifecycle on OwnedStoryListItemModel {
  bool get isArchived => lifecycleLabel == 'Archived';
}

/// Convenience for tests asserting domain enums mapped correctly.
StoryLifecycleStatus? lifecycleStatusFromLabel(String label) {
  return switch (label) {
    'Draft' => StoryLifecycleStatus.draft,
    'Ready for Review' => StoryLifecycleStatus.review,
    'Approved' => StoryLifecycleStatus.approved,
    'Published' => StoryLifecycleStatus.published,
    'Archived' => StoryLifecycleStatus.archived,
    _ => null,
  };
}

StoryVisibility? visibilityFromLabel(String label) {
  return switch (label) {
    'Private' => StoryVisibility.private,
    'Unlisted' => StoryVisibility.unlisted,
    'Community' => StoryVisibility.community,
    'Public' => StoryVisibility.public,
    _ => null,
  };
}

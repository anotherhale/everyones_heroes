import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_visibility.dart';

/// Owner-facing Story list item (application read model).
///
/// Includes private drafts. Does not imply Discoverability.
final class OwnedStorySummary {
  const OwnedStorySummary({
    required this.storyId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.lifecycleStatus,
    required this.visibility,
    required this.isRecorded,
    required this.isProcessingApproved,
    required this.isPublicationApproved,
    required this.isAiTransformationApproved,
    required this.hasMedia,
    this.duration,
    this.primaryRepresentationId,
  });

  final StoryId storyId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Duration? duration;
  final StoryLifecycleStatus lifecycleStatus;
  final StoryVisibility visibility;
  final bool isRecorded;
  final bool isProcessingApproved;
  final bool isPublicationApproved;
  final bool isAiTransformationApproved;
  final bool hasMedia;
  final StoryRepresentationId? primaryRepresentationId;
}

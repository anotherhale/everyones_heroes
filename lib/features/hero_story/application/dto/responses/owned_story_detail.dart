import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/representation_origin.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_representation_format.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_visibility.dart';

/// Owner-scoped Story detail (not discoverability-gated).
final class OwnedStoryDetail {
  const OwnedStoryDetail({
    required this.storyId,
    required this.heroId,
    required this.title,
    required this.hasProvisionalNarrative,
    required this.originalLanguage,
    required this.visibility,
    required this.lifecycleStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.isRecorded,
    required this.isProcessingApproved,
    required this.isPublicationApproved,
    required this.isAiTransformationApproved,
    required this.representations,
    this.primaryOriginalAudioId,
    this.primaryOriginalAudioDuration,
  });

  final StoryId storyId;
  final HeroId heroId;
  final String title;
  final bool hasProvisionalNarrative;
  final LanguageCode originalLanguage;
  final StoryVisibility visibility;
  final StoryLifecycleStatus lifecycleStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isRecorded;
  final bool isProcessingApproved;
  final bool isPublicationApproved;
  final bool isAiTransformationApproved;
  final List<OwnedRepresentationSummary> representations;
  final StoryRepresentationId? primaryOriginalAudioId;
  final Duration? primaryOriginalAudioDuration;
}

final class OwnedRepresentationSummary {
  const OwnedRepresentationSummary({
    required this.representationId,
    required this.format,
    required this.language,
    required this.origin,
    required this.isAuthoritative,
    required this.hasMedia,
    required this.isAiGenerated,
    required this.isApproved,
    this.duration,
    this.textContent,
    this.sourceRepresentationId,
  });

  final StoryRepresentationId representationId;
  final StoryRepresentationFormat format;
  final LanguageCode language;
  final RepresentationOrigin origin;
  final bool isAuthoritative;
  final bool hasMedia;
  final bool isAiGenerated;
  final bool isApproved;
  final Duration? duration;
  final String? textContent;
  final StoryRepresentationId? sourceRepresentationId;
}

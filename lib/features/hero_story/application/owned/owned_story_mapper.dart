import 'package:everyonesheroes/features/hero_story/application/dto/responses/owned_story_detail.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/owned_story_summary.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/entities/story_representation.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/representation_origin.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_representation_format.dart';

/// Projects owner Stories into application read models (HS.10).
final class OwnedStoryMapper {
  const OwnedStoryMapper._();

  static OwnedStorySummary toSummary(Story story) {
    final originalAudio = _primaryOriginalAudio(story);
    return OwnedStorySummary(
      storyId: story.id,
      title: story.title.value,
      createdAt: story.createdAt,
      updatedAt: story.updatedAt,
      duration: originalAudio?.duration,
      lifecycleStatus: story.lifecycleStatus,
      visibility: story.visibility,
      isRecorded: story.consent.isRecorded,
      isProcessingApproved: story.consent.isProcessingApproved,
      isPublicationApproved: story.consent.isPublicationApproved,
      isAiTransformationApproved: story.consent.isAiTransformationApproved,
      hasMedia: originalAudio?.mediaReference != null,
      primaryRepresentationId: originalAudio?.id,
    );
  }

  static OwnedStoryDetail toDetail(Story story) {
    final originalAudio = _primaryOriginalAudio(story);
    final representations = story.representations
        .map(
          (representation) => OwnedRepresentationSummary(
            representationId: representation.id,
            format: representation.format,
            language: representation.language,
            origin: representation.origin,
            isAuthoritative: representation.isAuthoritative,
            hasMedia: representation.mediaReference != null,
            duration: representation.duration,
          ),
        )
        .toList(growable: false);

    return OwnedStoryDetail(
      storyId: story.id,
      heroId: story.heroId,
      title: story.title.value,
      hasProvisionalNarrative: story.narrative.isProvisional,
      originalLanguage: story.originalLanguage,
      visibility: story.visibility,
      lifecycleStatus: story.lifecycleStatus,
      createdAt: story.createdAt,
      updatedAt: story.updatedAt,
      isRecorded: story.consent.isRecorded,
      isProcessingApproved: story.consent.isProcessingApproved,
      isPublicationApproved: story.consent.isPublicationApproved,
      isAiTransformationApproved: story.consent.isAiTransformationApproved,
      representations: List.unmodifiable(representations),
      primaryOriginalAudioId: originalAudio?.id,
      primaryOriginalAudioDuration: originalAudio?.duration,
    );
  }

  static StoryRepresentation? _primaryOriginalAudio(Story story) {
    for (final representation in story.representations) {
      if (representation.origin == RepresentationOrigin.original &&
          representation.format == StoryRepresentationFormat.audio) {
        return representation;
      }
    }
    for (final representation in story.representations) {
      if (representation.format == StoryRepresentationFormat.audio) {
        return representation;
      }
    }
    return story.representations.isEmpty ? null : story.representations.first;
  }
}
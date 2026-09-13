import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/playable_representation.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/story_experience_detail.dart';
import 'package:everyonesheroes/features/hero_story/application/experience/playable_representation_selector.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/entities/story_representation.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_representation_format.dart';

/// Projects a discoverable Story into a safe experience DTO (HS.7).
final class StoryExperienceMapper {
  const StoryExperienceMapper._();

  static StoryExperienceDetail fromStory({
    required Story story,
    required Hero hero,
    LanguageCode? preferredLanguage,
  }) {
    final sorted = PlayableRepresentationSelector.sortAuthoritative(
      story.representations,
      originalLanguage: story.originalLanguage,
      preferredLanguage: preferredLanguage,
    );

    final playables = sorted
        .map(toPlayable)
        .toList(growable: false);

    final primaryEntity = PlayableRepresentationSelector.select(
      candidates: story.representations,
      originalLanguage: story.originalLanguage,
      preferredLanguage: preferredLanguage,
    );

    return StoryExperienceDetail(
      storyId: story.id,
      heroId: story.heroId,
      heroDisplayName: hero.profile.displayName,
      title: story.title.value,
      narrativeBody: story.narrative.value,
      originalLanguage: story.originalLanguage,
      visibility: story.visibility,
      subjects: List.unmodifiable(story.classification.subjects),
      challenges: List.unmodifiable(story.classification.challenges),
      narrativeThemeIds: List.unmodifiable(
        story.classification.narrativeThemeIds,
      ),
      outcomes: List.unmodifiable(story.classification.outcomes),
      emotionalCharacters: List.unmodifiable(
        story.classification.emotionalCharacters,
      ),
      audience: story.classification.audience,
      geography: story.classification.geography,
      spiritualityCategory: story.spirituality.category,
      religiousTradition: story.spirituality.tradition,
      profanity: story.contentSuitability.profanity,
      violence: story.contentSuitability.violence,
      sexualContent: story.contentSuitability.sexualContent,
      substanceUse: story.contentSuitability.substanceUse,
      disturbingContent: story.contentSuitability.disturbingContent,
      playableRepresentations: playables,
      primaryPlayable: primaryEntity == null ? null : toPlayable(primaryEntity),
      createdAt: story.createdAt,
      updatedAt: story.updatedAt,
    );
  }

  static PlayableRepresentation toPlayable(StoryRepresentation representation) {
    final textLike = _isTextLike(representation.format);
    final text = representation.textContent?.trim();
    final hasText = text != null && text.isNotEmpty;
    return PlayableRepresentation(
      representationId: representation.id,
      format: representation.format,
      language: representation.language,
      duration: representation.duration,
      hasText: hasText,
      hasMedia: representation.mediaReference != null,
      textContent: textLike && hasText ? text : null,
    );
  }

  static bool _isTextLike(StoryRepresentationFormat format) {
    return format == StoryRepresentationFormat.written ||
        format == StoryRepresentationFormat.transcript ||
        format == StoryRepresentationFormat.script ||
        format == StoryRepresentationFormat.shortForm ||
        format == StoryRepresentationFormat.longForm;
  }
}

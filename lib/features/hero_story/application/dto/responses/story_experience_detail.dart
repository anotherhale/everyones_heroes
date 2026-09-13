import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/playable_representation.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/emotional_character.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/religious_tradition.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/spirituality_category.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_audience.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_challenge.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_outcome.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_subject.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/suitability_level.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_geography.dart';

/// Discoverability-gated Story experience read model (HS.7 / HS-ADR-049).
///
/// Derived at query time. Exposes narrative body only from discoverable Stories
/// with non-provisional narratives. Playable representations are authoritative
/// only. Does not expose raw Story aggregates, understanding payloads, or
/// unapproved representation text.
final class StoryExperienceDetail {
  const StoryExperienceDetail({
    required this.storyId,
    required this.heroId,
    required this.title,
    required this.narrativeBody,
    required this.originalLanguage,
    required this.visibility,
    required this.subjects,
    required this.challenges,
    required this.narrativeThemeIds,
    required this.outcomes,
    required this.emotionalCharacters,
    required this.spiritualityCategory,
    required this.profanity,
    required this.violence,
    required this.sexualContent,
    required this.substanceUse,
    required this.disturbingContent,
    required this.playableRepresentations,
    required this.primaryPlayable,
    required this.createdAt,
    required this.updatedAt,
    this.audience,
    this.geography,
    this.religiousTradition,
    this.heroDisplayName,
  });

  final StoryId storyId;
  final HeroId heroId;
  final String? heroDisplayName;
  final String title;
  final String narrativeBody;
  final LanguageCode originalLanguage;
  final StoryVisibility visibility;
  final List<StorySubject> subjects;
  final List<StoryChallenge> challenges;
  final List<NarrativeThemeId> narrativeThemeIds;
  final List<StoryOutcome> outcomes;
  final List<EmotionalCharacter> emotionalCharacters;
  final StoryAudience? audience;
  final StoryGeography? geography;
  final SpiritualityCategory spiritualityCategory;
  final ReligiousTradition? religiousTradition;
  final SuitabilityLevel profanity;
  final SuitabilityLevel violence;
  final SuitabilityLevel sexualContent;
  final SuitabilityLevel substanceUse;
  final SuitabilityLevel disturbingContent;
  final List<PlayableRepresentation> playableRepresentations;
  final PlayableRepresentation? primaryPlayable;
  final DateTime createdAt;
  final DateTime updatedAt;
}

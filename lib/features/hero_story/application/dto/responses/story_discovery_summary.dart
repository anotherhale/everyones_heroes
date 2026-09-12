import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/discovery_match_reason.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/emotional_character.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/religious_tradition.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/spirituality_category.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_audience.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_challenge.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_outcome.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_representation_format.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_subject.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/suitability_level.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_geography.dart';

/// Safe catalog discovery projection for a Story (HS-ADR-047).
///
/// Derived at query time — never a second canonical Story store.
/// Does not include narrative body, unapproved representation text,
/// understanding payloads, or private media references.
final class StoryDiscoverySummary {
  const StoryDiscoverySummary({
    required this.storyId,
    required this.heroId,
    required this.title,
    required this.originalLanguage,
    required this.availableLanguages,
    required this.subjects,
    required this.challenges,
    required this.narrativeThemeIds,
    required this.outcomes,
    required this.emotionalCharacters,
    required this.visibility,
    required this.spiritualityCategory,
    required this.profanity,
    required this.violence,
    required this.sexualContent,
    required this.substanceUse,
    required this.disturbingContent,
    required this.authoritativeRepresentations,
    required this.matchReasons,
    required this.updatedAt,
    required this.createdAt,
    this.audience,
    this.geography,
    this.religiousTradition,
    this.heroDisplayName,
  });

  final StoryId storyId;
  final HeroId heroId;
  final String title;
  final LanguageCode originalLanguage;
  final List<LanguageCode> availableLanguages;
  final List<StorySubject> subjects;
  final List<StoryChallenge> challenges;
  final List<NarrativeThemeId> narrativeThemeIds;
  final List<StoryOutcome> outcomes;
  final List<EmotionalCharacter> emotionalCharacters;
  final StoryAudience? audience;
  final StoryGeography? geography;
  final StoryVisibility visibility;
  final SpiritualityCategory spiritualityCategory;
  final ReligiousTradition? religiousTradition;
  final SuitabilityLevel profanity;
  final SuitabilityLevel violence;
  final SuitabilityLevel sexualContent;
  final SuitabilityLevel substanceUse;
  final SuitabilityLevel disturbingContent;
  final List<AuthoritativeRepresentationDescriptor> authoritativeRepresentations;
  final List<DiscoveryMatchReason> matchReasons;
  final DateTime updatedAt;
  final DateTime createdAt;
  final String? heroDisplayName;
}

/// Safe descriptor of an authoritative representation (no text bodies).
final class AuthoritativeRepresentationDescriptor {
  const AuthoritativeRepresentationDescriptor({
    required this.format,
    required this.language,
    this.duration,
  });

  final StoryRepresentationFormat format;
  final LanguageCode language;
  final Duration? duration;
}

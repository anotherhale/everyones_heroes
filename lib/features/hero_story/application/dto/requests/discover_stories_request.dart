import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/emotional_character.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/religious_tradition.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/spirituality_category.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_audience.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_challenge.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_outcome.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_representation_format.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_subject.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/suitability_level.dart';

/// Seeker-facing Story discovery filters with pagination (HS.6).
///
/// Discovery defaults (published + discoverable visibility + authoritative
/// representations) are applied by [DiscoverStoriesUseCase], not by callers.
final class DiscoverStoriesRequest {
  const DiscoverStoriesRequest({
    this.text,
    this.heroId,
    this.subjects = const [],
    this.challenges = const [],
    this.narrativeThemeIds = const [],
    this.outcomes = const [],
    this.emotionalCharacters = const [],
    this.audience,
    this.geographyCountry,
    this.geographyRegion,
    this.geographyCity,
    this.geographyCulturalContext,
    this.spiritualityCategory,
    this.religiousTradition,
    this.maxProfanity,
    this.maxViolence,
    this.maxSexualContent,
    this.maxSubstanceUse,
    this.maxDisturbingContent,
    this.formats = const [],
    this.minDuration,
    this.maxDuration,
    this.originalLanguage,
    this.availableLanguage,
    this.limit = 20,
    this.offset = 0,
  });

  final String? text;
  final HeroId? heroId;
  final List<StorySubject> subjects;
  final List<StoryChallenge> challenges;

  /// Plain catalog theme filters (D5). Callers may pass theme IDs that
  /// originated from a DiscoveryProfile; Discover does not load that profile.
  final List<NarrativeThemeId> narrativeThemeIds;
  final List<StoryOutcome> outcomes;
  final List<EmotionalCharacter> emotionalCharacters;
  final StoryAudience? audience;
  final String? geographyCountry;
  final String? geographyRegion;
  final String? geographyCity;
  final String? geographyCulturalContext;
  final SpiritualityCategory? spiritualityCategory;
  final ReligiousTradition? religiousTradition;
  final SuitabilityLevel? maxProfanity;
  final SuitabilityLevel? maxViolence;
  final SuitabilityLevel? maxSexualContent;
  final SuitabilityLevel? maxSubstanceUse;
  final SuitabilityLevel? maxDisturbingContent;
  final List<StoryRepresentationFormat> formats;
  final Duration? minDuration;
  final Duration? maxDuration;
  final LanguageCode? originalLanguage;
  final LanguageCode? availableLanguage;
  final int limit;
  final int offset;
}

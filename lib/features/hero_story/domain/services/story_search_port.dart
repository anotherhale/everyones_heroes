import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
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

/// Replaceable catalog query contract for Stories.
///
/// Catalog filtering only — does not personalize, rank, or score relevance.
abstract interface class StorySearchPort {
  Future<List<StoryId>> search(StorySearchQuery query);
}

/// Explicit multidimensional catalog criteria.
///
/// Within a multi-value dimension, matching is OR.
/// Across dimensions, matching is AND.
///
/// Duration filters use ANY-matching representation semantics.
/// When both [minDuration] and [maxDuration] are set, the same representation
/// must satisfy the full window.
final class StorySearchQuery {
  const StorySearchQuery({
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
    this.publishedOnly = true,
  });

  final String? text;
  final HeroId? heroId;
  final List<StorySubject> subjects;
  final List<StoryChallenge> challenges;
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
  final bool publishedOnly;
}

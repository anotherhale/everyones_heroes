import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/catalog_browse_dimension.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/emotional_character.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_audience.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_challenge.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_outcome.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_representation_format.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_subject.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/suitability_level.dart';

/// Browse Stories by one primary catalog dimension (HS.6).
///
/// Free-text is not required. Discovery eligibility defaults apply.
final class BrowseStoriesByCatalogRequest {
  const BrowseStoriesByCatalogRequest({
    required this.dimension,
    this.subject,
    this.challenge,
    this.narrativeThemeId,
    this.format,
    this.language,
    this.outcome,
    this.emotionalCharacter,
    this.audience,
    this.maxProfanity,
    this.maxViolence,
    this.maxSexualContent,
    this.maxSubstanceUse,
    this.maxDisturbingContent,
    this.limit = 20,
    this.offset = 0,
  });

  final CatalogBrowseDimension dimension;
  final StorySubject? subject;
  final StoryChallenge? challenge;
  final NarrativeThemeId? narrativeThemeId;
  final StoryRepresentationFormat? format;
  final LanguageCode? language;
  final StoryOutcome? outcome;
  final EmotionalCharacter? emotionalCharacter;
  final StoryAudience? audience;
  final SuitabilityLevel? maxProfanity;
  final SuitabilityLevel? maxViolence;
  final SuitabilityLevel? maxSexualContent;
  final SuitabilityLevel? maxSubstanceUse;
  final SuitabilityLevel? maxDisturbingContent;
  final int limit;
  final int offset;
}

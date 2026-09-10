import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_audience.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_challenge.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_subject.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/suitability_level.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';

/// Replaceable search/discovery contract for Stories.
///
/// Catalog filtering only — does not personalize.
abstract interface class StorySearchPort {
  Future<List<StoryId>> search(StorySearchQuery query);
}

final class StorySearchQuery {
  const StorySearchQuery({
    this.text,
    this.heroId,
    this.subjects = const [],
    this.challenges = const [],
    this.narrativeThemeIds = const [],
    this.originalLanguage,
    this.availableLanguage,
    this.audience,
    this.maxProfanity,
    this.publishedOnly = true,
  });

  final String? text;
  final HeroId? heroId;
  final List<StorySubject> subjects;
  final List<StoryChallenge> challenges;
  final List<NarrativeThemeId> narrativeThemeIds;
  final LanguageCode? originalLanguage;
  final LanguageCode? availableLanguage;
  final StoryAudience? audience;
  final SuitabilityLevel? maxProfanity;
  final bool publishedOnly;
}

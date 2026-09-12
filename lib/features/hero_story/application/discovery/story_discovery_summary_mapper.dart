import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/discover_stories_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/story_discovery_summary.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/discovery_match_reason.dart';

/// Projects canonical Story/Hero state into safe discovery summaries.
final class StoryDiscoverySummaryMapper {
  const StoryDiscoverySummaryMapper._();

  static const int defaultLimit = 20;
  static const int maxLimit = 100;

  static StoryDiscoverySummary fromStory({
    required Story story,
    Hero? hero,
    List<DiscoveryMatchReason> matchReasons = const [],
  }) {
    final authoritative = story.representations
        .where((representation) => representation.isAuthoritative)
        .toList(growable: false);

    final languages = <LanguageCode>{
      story.originalLanguage,
      ...authoritative.map((representation) => representation.language),
    }.toList(growable: false);

    return StoryDiscoverySummary(
      storyId: story.id,
      heroId: story.heroId,
      title: story.title.value,
      originalLanguage: story.originalLanguage,
      availableLanguages: languages,
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
      visibility: story.visibility,
      spiritualityCategory: story.spirituality.category,
      religiousTradition: story.spirituality.tradition,
      profanity: story.contentSuitability.profanity,
      violence: story.contentSuitability.violence,
      sexualContent: story.contentSuitability.sexualContent,
      substanceUse: story.contentSuitability.substanceUse,
      disturbingContent: story.contentSuitability.disturbingContent,
      authoritativeRepresentations: authoritative
          .map(
            (representation) => AuthoritativeRepresentationDescriptor(
              format: representation.format,
              language: representation.language,
              duration: representation.duration,
            ),
          )
          .toList(growable: false),
      matchReasons: List.unmodifiable(matchReasons),
      updatedAt: story.updatedAt,
      createdAt: story.createdAt,
      heroDisplayName: hero?.profile.displayName,
    );
  }

  static List<DiscoveryMatchReason> matchReasonsFor(
    DiscoverStoriesRequest request,
  ) {
    final reasons = <DiscoveryMatchReason>[];
    if (request.text != null && request.text!.trim().isNotEmpty) {
      reasons.add(DiscoveryMatchReason.text);
    }
    if (request.heroId != null) {
      reasons.add(DiscoveryMatchReason.hero);
    }
    if (request.subjects.isNotEmpty) {
      reasons.add(DiscoveryMatchReason.subject);
    }
    if (request.challenges.isNotEmpty) {
      reasons.add(DiscoveryMatchReason.challenge);
    }
    if (request.narrativeThemeIds.isNotEmpty) {
      reasons.add(DiscoveryMatchReason.narrativeTheme);
    }
    if (request.outcomes.isNotEmpty) {
      reasons.add(DiscoveryMatchReason.outcome);
    }
    if (request.emotionalCharacters.isNotEmpty) {
      reasons.add(DiscoveryMatchReason.emotionalCharacter);
    }
    if (request.audience != null) {
      reasons.add(DiscoveryMatchReason.audience);
    }
    if (_hasText(request.geographyCountry) ||
        _hasText(request.geographyRegion) ||
        _hasText(request.geographyCity) ||
        _hasText(request.geographyCulturalContext)) {
      reasons.add(DiscoveryMatchReason.geography);
    }
    if (request.spiritualityCategory != null ||
        request.religiousTradition != null) {
      reasons.add(DiscoveryMatchReason.spirituality);
    }
    if (request.maxProfanity != null ||
        request.maxViolence != null ||
        request.maxSexualContent != null ||
        request.maxSubstanceUse != null ||
        request.maxDisturbingContent != null) {
      reasons.add(DiscoveryMatchReason.suitability);
    }
    if (request.formats.isNotEmpty) {
      reasons.add(DiscoveryMatchReason.format);
    }
    if (request.minDuration != null || request.maxDuration != null) {
      reasons.add(DiscoveryMatchReason.duration);
    }
    if (request.originalLanguage != null) {
      reasons.add(DiscoveryMatchReason.originalLanguage);
    }
    if (request.availableLanguage != null) {
      reasons.add(DiscoveryMatchReason.availableLanguage);
    }
    return List.unmodifiable(reasons);
  }

  static void validatePagination({required int limit, required int offset}) {
    if (offset < 0) {
      throw ArgumentError.value(offset, 'offset', 'must be >= 0');
    }
    if (limit < 1 || limit > maxLimit) {
      throw ArgumentError.value(
        limit,
        'limit',
        'must be between 1 and $maxLimit',
      );
    }
  }

  /// Deterministic Story ordering: updatedAt desc, storyId asc.
  static int compareStories(Story a, Story b) {
    final byUpdated = b.updatedAt.compareTo(a.updatedAt);
    if (byUpdated != 0) {
      return byUpdated;
    }
    return a.id.value.compareTo(b.id.value);
  }

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;
}

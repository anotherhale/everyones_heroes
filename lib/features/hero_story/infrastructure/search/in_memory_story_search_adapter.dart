import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/entities/story_representation.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/suitability_level.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_search_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_geography.dart';

/// Deterministic in-memory catalog search.
///
/// Does not personalize, rank, or depend on Discovery/Personalization.
final class InMemoryStorySearchAdapter implements StorySearchPort {
  InMemoryStorySearchAdapter(this._storyRepository);

  final StoryRepository _storyRepository;

  @override
  Future<List<StoryId>> search(StorySearchQuery query) async {
    final stories = await _storyRepository.findAll();

    return stories
        .where((story) => _matches(story, query))
        .map((story) => story.id)
        .toList(growable: false);
  }

  bool _matches(Story story, StorySearchQuery query) {
    if (query.publishedOnly &&
        story.lifecycleStatus != StoryLifecycleStatus.published) {
      return false;
    }

    if (query.visibilities.isNotEmpty &&
        !query.visibilities.contains(story.visibility)) {
      return false;
    }

    if (query.heroId != null && story.heroId != query.heroId) {
      return false;
    }

    if (query.originalLanguage != null &&
        story.originalLanguage != query.originalLanguage) {
      return false;
    }

    final matchingRepresentations = query.authoritativeRepresentationsOnly
        ? story.representations.where((r) => r.isAuthoritative)
        : story.representations;

    if (query.availableLanguage != null &&
        !_availableLanguages(
          story,
          matchingRepresentations,
        ).contains(query.availableLanguage)) {
      return false;
    }

    final classification = story.classification;

    if (query.subjects.isNotEmpty &&
        !query.subjects.any(classification.subjects.contains)) {
      return false;
    }

    if (query.challenges.isNotEmpty &&
        !query.challenges.any(classification.challenges.contains)) {
      return false;
    }

    if (query.narrativeThemeIds.isNotEmpty &&
        !query.narrativeThemeIds.any(
          classification.narrativeThemeIds.contains,
        )) {
      return false;
    }

    if (query.outcomes.isNotEmpty &&
        !query.outcomes.any(classification.outcomes.contains)) {
      return false;
    }

    if (query.emotionalCharacters.isNotEmpty &&
        !query.emotionalCharacters.any(
          classification.emotionalCharacters.contains,
        )) {
      return false;
    }

    if (query.audience != null && classification.audience != query.audience) {
      return false;
    }

    if (!_matchesGeography(classification.geography, query)) {
      return false;
    }

    if (query.spiritualityCategory != null &&
        story.spirituality.category != query.spiritualityCategory) {
      return false;
    }

    if (query.religiousTradition != null &&
        story.spirituality.tradition != query.religiousTradition) {
      return false;
    }

    final suitability = story.contentSuitability;
    if (!_withinMax(suitability.profanity, query.maxProfanity) ||
        !_withinMax(suitability.violence, query.maxViolence) ||
        !_withinMax(suitability.sexualContent, query.maxSexualContent) ||
        !_withinMax(suitability.substanceUse, query.maxSubstanceUse) ||
        !_withinMax(
          suitability.disturbingContent,
          query.maxDisturbingContent,
        )) {
      return false;
    }

    if (query.formats.isNotEmpty &&
        !matchingRepresentations.any(
          (representation) => query.formats.contains(representation.format),
        )) {
      return false;
    }

    if (!_matchesDuration(matchingRepresentations, query)) {
      return false;
    }

    if (query.text != null && query.text!.trim().isNotEmpty) {
      final needle = query.text!.trim().toLowerCase();
      final haystack =
          '${story.title.value} ${story.narrative.value}'.toLowerCase();
      if (!haystack.contains(needle)) {
        return false;
      }
    }

    return true;
  }

  Set<LanguageCode> _availableLanguages(
    Story story,
    Iterable<StoryRepresentation> representations,
  ) => {
    story.originalLanguage,
    ...representations.map((r) => r.language),
  };

  bool _matchesGeography(StoryGeography? geography, StorySearchQuery query) {
    final hasGeographyConstraint =
        _hasText(query.geographyCountry) ||
        _hasText(query.geographyRegion) ||
        _hasText(query.geographyCity) ||
        _hasText(query.geographyCulturalContext);

    if (!hasGeographyConstraint) {
      return true;
    }

    if (geography == null) {
      return false;
    }

    if (_hasText(query.geographyCountry) &&
        !_containsIgnoreCase(geography.country, query.geographyCountry!)) {
      return false;
    }
    if (_hasText(query.geographyRegion) &&
        !_containsIgnoreCase(geography.region, query.geographyRegion!)) {
      return false;
    }
    if (_hasText(query.geographyCity) &&
        !_containsIgnoreCase(geography.city, query.geographyCity!)) {
      return false;
    }
    if (_hasText(query.geographyCulturalContext) &&
        !_containsIgnoreCase(
          geography.culturalContext,
          query.geographyCulturalContext!,
        )) {
      return false;
    }

    return true;
  }

  bool _matchesDuration(
    Iterable<StoryRepresentation> representations,
    StorySearchQuery query,
  ) {
    final minDuration = query.minDuration;
    final maxDuration = query.maxDuration;

    if (minDuration == null && maxDuration == null) {
      return true;
    }

    // When both bounds are set, the same representation must satisfy the window.
    if (minDuration != null && maxDuration != null) {
      return representations.any((representation) {
        final duration = representation.duration;
        if (duration == null) {
          return false;
        }
        return duration >= minDuration && duration <= maxDuration;
      });
    }

    if (minDuration != null) {
      return representations.any((representation) {
        final duration = representation.duration;
        return duration != null && duration >= minDuration;
      });
    }

    return representations.any((representation) {
      final duration = representation.duration;
      return duration != null && duration <= maxDuration!;
    });
  }

  bool _withinMax(SuitabilityLevel actual, SuitabilityLevel? max) {
    if (max == null) {
      return true;
    }
    return actual.index <= max.index;
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  bool _containsIgnoreCase(String? haystack, String needle) {
    if (haystack == null) {
      return false;
    }
    return haystack.toLowerCase().contains(needle.trim().toLowerCase());
  }
}

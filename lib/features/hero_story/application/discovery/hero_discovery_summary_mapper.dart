import 'package:everyonesheroes/features/hero_story/application/dto/requests/discover_heroes_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/hero_discovery_summary.dart';
import 'package:everyonesheroes/features/hero_story/application/discovery/story_discovery_summary_mapper.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/discovery_match_reason.dart';

final class HeroDiscoverySummaryMapper {
  const HeroDiscoverySummaryMapper._();

  static HeroDiscoverySummary fromHero({
    required Hero hero,
    List<DiscoveryMatchReason> matchReasons = const [],
  }) {
    return HeroDiscoverySummary(
      heroId: hero.id,
      displayName: hero.profile.displayName,
      biography: hero.profile.biography,
      experienceAreas: List.unmodifiable(hero.profile.experienceAreas),
      languages: List.unmodifiable(hero.profile.languages),
      visibility: hero.visibility,
      createdAt: hero.createdAt,
      matchReasons: List.unmodifiable(matchReasons),
    );
  }

  static List<DiscoveryMatchReason> matchReasonsFor(
    DiscoverHeroesRequest request,
  ) {
    final reasons = <DiscoveryMatchReason>[];
    if (request.text != null && request.text!.trim().isNotEmpty) {
      reasons.add(DiscoveryMatchReason.text);
    }
    if (request.experienceArea != null &&
        request.experienceArea!.trim().isNotEmpty) {
      reasons.add(DiscoveryMatchReason.experienceArea);
    }
    if (request.language != null) {
      reasons.add(DiscoveryMatchReason.availableLanguage);
    }
    return List.unmodifiable(reasons);
  }

  static void validatePagination({required int limit, required int offset}) {
    StoryDiscoverySummaryMapper.validatePagination(
      limit: limit,
      offset: offset,
    );
  }

  /// Deterministic Hero ordering: createdAt desc, heroId asc.
  static int compareHeroes(Hero a, Hero b) {
    final byCreated = b.createdAt.compareTo(a.createdAt);
    if (byCreated != 0) {
      return byCreated;
    }
    return a.id.value.compareTo(b.id.value);
  }
}

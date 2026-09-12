import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/discovery/story_discovery_summary_mapper.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/discover_stories_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/discover_stories_response.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/hero_discoverability_policy.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_discoverability_policy.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_search_port.dart';

/// Seeker-facing Story discovery: eligibility + search + safe summaries.
///
/// Does not mutate aggregates or publish domain events.
final class DiscoverStoriesUseCase
    implements UseCase<DiscoverStoriesRequest, DiscoverStoriesResponse> {
  const DiscoverStoriesUseCase({
    required this._storySearchPort,
    required this._storyRepository,
    required this._heroRepository,
  });

  final StorySearchPort _storySearchPort;
  final StoryRepository _storyRepository;
  final HeroRepository _heroRepository;

  @override
  Future<Result<DiscoverStoriesResponse>> execute(
    DiscoverStoriesRequest request,
  ) async {
    try {
      StoryDiscoverySummaryMapper.validatePagination(
        limit: request.limit,
        offset: request.offset,
      );

      final query = StorySearchQuery(
        text: request.text,
        heroId: request.heroId,
        subjects: request.subjects,
        challenges: request.challenges,
        narrativeThemeIds: request.narrativeThemeIds,
        outcomes: request.outcomes,
        emotionalCharacters: request.emotionalCharacters,
        audience: request.audience,
        geographyCountry: request.geographyCountry,
        geographyRegion: request.geographyRegion,
        geographyCity: request.geographyCity,
        geographyCulturalContext: request.geographyCulturalContext,
        spiritualityCategory: request.spiritualityCategory,
        religiousTradition: request.religiousTradition,
        maxProfanity: request.maxProfanity,
        maxViolence: request.maxViolence,
        maxSexualContent: request.maxSexualContent,
        maxSubstanceUse: request.maxSubstanceUse,
        maxDisturbingContent: request.maxDisturbingContent,
        formats: request.formats,
        minDuration: request.minDuration,
        maxDuration: request.maxDuration,
        originalLanguage: request.originalLanguage,
        availableLanguage: request.availableLanguage,
        publishedOnly: true,
        visibilities: StoryDiscoverabilityPolicy.discoverableVisibilityList,
        authoritativeRepresentationsOnly: true,
      );

      final ids = await _storySearchPort.search(query);
      final matchReasons = StoryDiscoverySummaryMapper.matchReasonsFor(request);

      final eligible = <({Story story, Hero hero})>[];
      final seen = <String>{};

      for (final id in ids) {
        if (!seen.add(id.value)) {
          continue;
        }

        final story = await _storyRepository.findById(id);
        if (story == null) {
          continue;
        }
        if (!StoryDiscoverabilityPolicy.isDiscoverable(story)) {
          continue;
        }

        final hero = await _heroRepository.findById(story.heroId);
        if (hero == null || !HeroDiscoverabilityPolicy.isDiscoverable(hero)) {
          continue;
        }

        eligible.add((story: story, hero: hero));
      }

      eligible.sort(
        (a, b) => StoryDiscoverySummaryMapper.compareStories(a.story, b.story),
      );

      final totalCount = eligible.length;
      final page = eligible.skip(request.offset).take(request.limit).toList();

      final items = page
          .map(
            (entry) => StoryDiscoverySummaryMapper.fromStory(
              story: entry.story,
              hero: entry.hero,
              matchReasons: matchReasons,
            ),
          )
          .toList(growable: false);

      final nextOffset = request.offset + items.length < totalCount
          ? request.offset + items.length
          : null;

      return Success(
        DiscoverStoriesResponse(
          items: items,
          totalCount: totalCount,
          nextOffset: nextOffset,
        ),
      );
    } on ArgumentError catch (e) {
      return Failure('${e.message ?? e}');
    } catch (e) {
      return Failure('Failed to discover stories: $e');
    }
  }
}

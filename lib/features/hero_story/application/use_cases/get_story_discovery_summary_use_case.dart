import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/discovery/story_discovery_summary_mapper.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/get_story_discovery_summary_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/story_discovery_summary.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/hero_discoverability_policy.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_discoverability_policy.dart';

/// Returns a discovery summary by id only when the Story is discoverable.
///
/// Prevents unlisted / private leakage via known-id lookup APIs.
final class GetStoryDiscoverySummaryUseCase
    implements
        UseCase<GetStoryDiscoverySummaryRequest, StoryDiscoverySummary> {
  const GetStoryDiscoverySummaryUseCase({
    required this._storyRepository,
    required this._heroRepository,
  });

  final StoryRepository _storyRepository;
  final HeroRepository _heroRepository;

  @override
  Future<Result<StoryDiscoverySummary>> execute(
    GetStoryDiscoverySummaryRequest request,
  ) async {
    try {
      final story = await _storyRepository.findById(request.storyId);
      if (story == null) {
        return Failure('Story not found: ${request.storyId.value}');
      }

      if (!StoryDiscoverabilityPolicy.isDiscoverable(story)) {
        return Failure(
          'Story is not discoverable: ${request.storyId.value}',
        );
      }

      final hero = await _heroRepository.findById(story.heroId);
      if (hero == null || !HeroDiscoverabilityPolicy.isDiscoverable(hero)) {
        return Failure(
          'Story is not discoverable: ${request.storyId.value}',
        );
      }

      return Success(
        StoryDiscoverySummaryMapper.fromStory(story: story, hero: hero),
      );
    } catch (e) {
      return Failure('Failed to get story discovery summary: $e');
    }
  }
}

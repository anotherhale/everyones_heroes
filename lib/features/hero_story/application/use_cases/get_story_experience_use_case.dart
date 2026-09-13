import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/get_story_experience_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/story_experience_detail.dart';
import 'package:everyonesheroes/features/hero_story/application/experience/story_experience_mapper.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/hero_discoverability_policy.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_discoverability_policy.dart';

/// Returns Story experience detail only when Story and Hero are discoverable.
///
/// Known-id access cannot bypass discoverability (HS.7 D4). Private and
/// unlisted Stories fail closed. Unapproved representations are excluded from
/// playable lists. Narrative body is exposed only for eligible Stories (D2).
final class GetStoryExperienceUseCase
    implements UseCase<GetStoryExperienceRequest, StoryExperienceDetail> {
  const GetStoryExperienceUseCase({
    required this._storyRepository,
    required this._heroRepository,
  });

  final StoryRepository _storyRepository;
  final HeroRepository _heroRepository;

  @override
  Future<Result<StoryExperienceDetail>> execute(
    GetStoryExperienceRequest request,
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
        StoryExperienceMapper.fromStory(
          story: story,
          hero: hero,
          preferredLanguage: request.preferredLanguage,
        ),
      );
    } catch (e) {
      return Failure('Failed to get story experience: $e');
    }
  }
}

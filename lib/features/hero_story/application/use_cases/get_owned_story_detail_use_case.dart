import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/get_owned_story_detail_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/owned_story_detail.dart';
import 'package:everyonesheroes/features/hero_story/application/owned/owned_story_mapper.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';

/// Returns Story detail for the owning Hero without Discoverability gates.
///
/// Private drafts are readable by their owner. Seeker experience use cases
/// remain fail-closed (HS.7 D4).
final class GetOwnedStoryDetailUseCase
    implements UseCase<GetOwnedStoryDetailRequest, OwnedStoryDetail> {
  const GetOwnedStoryDetailUseCase({
    required this._storyRepository,
    required this._heroRepository,
  });

  final StoryRepository _storyRepository;
  final HeroRepository _heroRepository;

  @override
  Future<Result<OwnedStoryDetail>> execute(
    GetOwnedStoryDetailRequest request,
  ) async {
    try {
      final hero = await _heroRepository.findById(request.ownerHeroId);
      if (hero == null) {
        return Failure('Hero not found: ${request.ownerHeroId.value}');
      }

      final story = await _storyRepository.findById(request.storyId);
      if (story == null) {
        return Failure('Story not found: ${request.storyId.value}');
      }

      if (story.heroId != request.ownerHeroId) {
        return Failure(
          'Story is not owned by hero: ${request.storyId.value}',
        );
      }

      return Success(OwnedStoryMapper.toDetail(story));
    } catch (e) {
      return Failure('Failed to get owned story detail: $e');
    }
  }
}

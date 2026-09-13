import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/discover_stories_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/list_hero_stories_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/discover_stories_response.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/discover_stories_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';

/// Lists a Hero's Stories exclusively through HS.6 DiscoverStories (HS.7 D5).
///
/// Does not call Search* or unfiltered repositories for seeker eligibility.
final class ListHeroStoriesUseCase
    implements UseCase<ListHeroStoriesRequest, DiscoverStoriesResponse> {
  const ListHeroStoriesUseCase({required this._discoverStoriesUseCase});

  final DiscoverStoriesUseCase _discoverStoriesUseCase;

  @override
  Future<Result<DiscoverStoriesResponse>> execute(
    ListHeroStoriesRequest request,
  ) {
    return _discoverStoriesUseCase.execute(
      DiscoverStoriesRequest(
        heroId: request.heroId,
        limit: request.limit,
        offset: request.offset,
      ),
    );
  }
}

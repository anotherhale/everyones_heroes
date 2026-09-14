import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';

/// Owner-scoped story listing (includes private drafts).
///
/// Intentionally does **not** use Discover* — private drafts must remain
/// undiscoverable (HS.9 / HS-ADR-043 continuity).
final class ListHeroOwnedStoriesRequest {
  const ListHeroOwnedStoriesRequest({required this.heroId});

  final HeroId heroId;
}

final class ListHeroOwnedStoriesUseCase
    implements UseCase<ListHeroOwnedStoriesRequest, List<Story>> {
  const ListHeroOwnedStoriesUseCase({
    required this._storyRepository,
    required this._heroRepository,
  });

  final StoryRepository _storyRepository;
  final HeroRepository _heroRepository;

  @override
  Future<Result<List<Story>>> execute(
    ListHeroOwnedStoriesRequest request,
  ) async {
    final hero = await _heroRepository.findById(request.heroId);
    if (hero == null) {
      return Failure('Hero not found: ${request.heroId.value}');
    }

    final stories = await _storyRepository.findByHeroId(request.heroId);
    stories.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return Success(List.unmodifiable(stories));
  }
}

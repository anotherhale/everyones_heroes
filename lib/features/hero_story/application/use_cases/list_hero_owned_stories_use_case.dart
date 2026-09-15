import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/owned_story_summary.dart';
import 'package:everyonesheroes/features/hero_story/application/owned/owned_story_mapper.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';

/// Owner-scoped story listing (includes private drafts).
///
/// Intentionally does **not** use Discover* — private drafts must remain
/// undiscoverable (HS.9 / HS-ADR-043 continuity).
///
/// Ordering: newest [updatedAt] first (existing HS.9 convention).
/// Archived Stories are excluded by default (HS.10 My Stories).
final class ListHeroOwnedStoriesRequest {
  const ListHeroOwnedStoriesRequest({
    required this.heroId,
    this.includeArchived = false,
  });

  final HeroId heroId;

  /// When false (default), Stories with lifecycle [StoryLifecycleStatus.archived]
  /// are omitted from the active My Stories list.
  final bool includeArchived;
}

final class ListHeroOwnedStoriesUseCase
    implements UseCase<ListHeroOwnedStoriesRequest, List<OwnedStorySummary>> {
  const ListHeroOwnedStoriesUseCase({
    required this._storyRepository,
    required this._heroRepository,
  });

  final StoryRepository _storyRepository;
  final HeroRepository _heroRepository;

  @override
  Future<Result<List<OwnedStorySummary>>> execute(
    ListHeroOwnedStoriesRequest request,
  ) async {
    final hero = await _heroRepository.findById(request.heroId);
    if (hero == null) {
      return Failure('Hero not found: ${request.heroId.value}');
    }

    final stories = await _storyRepository.findByHeroId(request.heroId);
    final filtered = request.includeArchived
        ? stories
        : stories
              .where(
                (story) =>
                    story.lifecycleStatus != StoryLifecycleStatus.archived,
              )
              .toList();
    filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final summaries = filtered
        .map(OwnedStoryMapper.toSummary)
        .toList(growable: false);
    return Success(List.unmodifiable(summaries));
  }
}

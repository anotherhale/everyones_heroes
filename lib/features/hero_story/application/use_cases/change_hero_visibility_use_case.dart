import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/change_hero_visibility_request.dart';
import 'package:everyonesheroes/features/hero_story/application/services/discoverable_story_candidate_sync.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';

/// Owner composition for [Hero.changeVisibility] (HS.FG.3).
///
/// Does not publish Stories, mutate Discovery preference, or emit behavioral
/// evidence. Discovery eligibility remains owned by
/// [HeroDiscoverabilityPolicy] / [StoryDiscoverabilityPolicy].
///
/// J.2 Slice 5: when platform sync is wired, refreshes projection for each
/// published Story owned by this Hero (Hero visibility gates eligibility).
final class ChangeHeroVisibilityUseCase
    implements UseCase<ChangeHeroVisibilityRequest, Hero> {
  const ChangeHeroVisibilityUseCase({
    required HeroRepository heroRepository,
    StoryRepository? storyRepository,
    DiscoverableStoryCandidateSync? candidateSync,
  })  : _heroRepository = heroRepository,
        _storyRepository = storyRepository,
        _candidateSync = candidateSync;

  final HeroRepository _heroRepository;
  final StoryRepository? _storyRepository;
  final DiscoverableStoryCandidateSync? _candidateSync;

  @override
  Future<Result<Hero>> execute(ChangeHeroVisibilityRequest request) async {
    Hero? hero;
    var previousVisibility = request.visibility;

    try {
      if (request.ownerHeroId != request.heroId) {
        return Failure(
          'Not authorized to change visibility for hero: '
          '${request.heroId.value}',
        );
      }

      hero = await _heroRepository.findById(request.heroId);
      if (hero == null) {
        return Failure('Hero not found: ${request.heroId.value}');
      }

      previousVisibility = hero.visibility;

      if (previousVisibility == request.visibility) {
        return Success(hero);
      }

      hero.changeVisibility(request.visibility);
      await _heroRepository.save(hero);

      await _syncPublishedStories(hero);

      return Success(hero);
    } catch (e) {
      if (hero != null && hero.visibility != previousVisibility) {
        try {
          hero.changeVisibility(previousVisibility);
        } catch (_) {
          // Preserve best-effort prior visibility; surface original failure.
        }
      }
      return Failure('Failed to change hero visibility: $e');
    }
  }

  Future<void> _syncPublishedStories(Hero hero) async {
    final sync = _candidateSync;
    final stories = _storyRepository;
    if (sync == null || stories == null) {
      return;
    }
    final owned = await stories.findByHeroId(hero.id);
    for (final story in owned) {
      if (story.lifecycleStatus == StoryLifecycleStatus.published) {
        await sync.sync(story: story, hero: hero);
      }
    }
  }
}

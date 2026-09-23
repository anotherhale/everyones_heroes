import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/change_hero_visibility_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';

/// Owner composition for [Hero.changeVisibility] (HS.FG.3).
///
/// Does not publish Stories, mutate Discovery preference, or emit behavioral
/// evidence. Discovery eligibility remains owned by
/// [HeroDiscoverabilityPolicy] / [StoryDiscoverabilityPolicy].
final class ChangeHeroVisibilityUseCase
    implements UseCase<ChangeHeroVisibilityRequest, Hero> {
  const ChangeHeroVisibilityUseCase({
    required HeroRepository heroRepository,
  }) : _heroRepository = heroRepository;

  final HeroRepository _heroRepository;

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
}

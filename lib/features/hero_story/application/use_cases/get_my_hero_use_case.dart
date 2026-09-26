import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/get_my_hero_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';

/// Returns the owner's active Hero without a public discoverability gate (HP.1).
///
/// Ownership is established by the caller supplying the active Hero id from
/// [ActiveLocalHeroStore] / [ensureActiveLocalHeroProvider]. Private Heroes
/// remain fully readable on this path.
///
/// Does not invent a MyHeroProfile aggregate — returns the existing [Hero].
final class GetMyHeroUseCase implements UseCase<GetMyHeroRequest, Hero> {
  const GetMyHeroUseCase({required this._heroRepository});

  final HeroRepository _heroRepository;

  @override
  Future<Result<Hero>> execute(GetMyHeroRequest request) async {
    try {
      final hero = await _heroRepository.findById(request.heroId);
      if (hero == null) {
        return Failure('Hero not found: ${request.heroId.value}');
      }

      if (!hero.isActive) {
        return Failure('Hero is not active: ${request.heroId.value}');
      }

      return Success(hero);
    } catch (e) {
      return Failure('Failed to get my hero: $e');
    }
  }
}

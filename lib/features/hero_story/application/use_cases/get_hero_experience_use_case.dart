import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/get_hero_experience_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/hero_experience_detail.dart';
import 'package:everyonesheroes/features/hero_story/application/experience/hero_experience_mapper.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/hero_discoverability_policy.dart';

/// Returns Hero experience detail only when the Hero is discoverable (HS.7 D6).
final class GetHeroExperienceUseCase
    implements UseCase<GetHeroExperienceRequest, HeroExperienceDetail> {
  const GetHeroExperienceUseCase({required this._heroRepository});

  final HeroRepository _heroRepository;

  @override
  Future<Result<HeroExperienceDetail>> execute(
    GetHeroExperienceRequest request,
  ) async {
    try {
      final hero = await _heroRepository.findById(request.heroId);
      if (hero == null) {
        return Failure('Hero not found: ${request.heroId.value}');
      }

      if (!HeroDiscoverabilityPolicy.isDiscoverable(hero)) {
        return Failure(
          'Hero is not discoverable: ${request.heroId.value}',
        );
      }

      return Success(HeroExperienceMapper.fromHero(hero));
    } catch (e) {
      return Failure('Failed to get hero experience: $e');
    }
  }
}

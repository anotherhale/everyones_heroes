import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/update_hero_profile_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';

final class UpdateHeroProfileUseCase
    implements UseCase<UpdateHeroProfileRequest, Hero> {
  const UpdateHeroProfileUseCase({
    required this._heroRepository,
    required this._eventBus,
  });

  final HeroRepository _heroRepository;
  final EventBus _eventBus;

  @override
  Future<Result<Hero>> execute(UpdateHeroProfileRequest request) async {
    try {
      final hero = await _heroRepository.findById(request.heroId);
      if (hero == null) {
        return Failure('Hero not found: ${request.heroId.value}');
      }

      hero.updateProfile(request.profile);
      await _heroRepository.save(hero);

      for (final event in hero.pullDomainEvents()) {
        await _eventBus.publish(event);
      }

      return Success(hero);
    } catch (e) {
      return Failure('Failed to update hero profile: $e');
    }
  }
}

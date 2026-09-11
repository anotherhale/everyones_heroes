import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/create_hero_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';

final class CreateHeroUseCase implements UseCase<CreateHeroRequest, Hero> {
  const CreateHeroUseCase({
    required this._heroRepository,
    required this._eventBus,
  });

  final HeroRepository _heroRepository;
  final EventBus _eventBus;

  @override
  Future<Result<Hero>> execute(CreateHeroRequest request) async {
    try {
      final hero = Hero.create(
        id: request.heroId,
        profile: request.profile,
        identityUserId: request.identityUserId,
        visibility: request.visibility,
      );

      await _heroRepository.save(hero);

      for (final event in hero.pullDomainEvents()) {
        await _eventBus.publish(event);
      }

      return Success(hero);
    } catch (e) {
      return Failure('Failed to create hero: $e');
    }
  }
}

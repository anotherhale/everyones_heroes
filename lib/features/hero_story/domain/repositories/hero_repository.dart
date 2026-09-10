import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';

abstract interface class HeroRepository {
  Future<void> save(Hero hero);

  Future<Hero?> findById(HeroId id);

  Future<bool> exists(HeroId id);

  Future<void> delete(HeroId id);

  Future<List<Hero>> findAll();
}

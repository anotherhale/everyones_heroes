import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';

class InMemoryHeroRepository implements HeroRepository {
  final Map<HeroId, Hero> _store = {};

  @override
  Future<void> save(Hero hero) async {
    _store[hero.id] = hero;
  }

  @override
  Future<Hero?> findById(HeroId id) async {
    return _store[id];
  }

  @override
  Future<bool> exists(HeroId id) async {
    return _store.containsKey(id);
  }

  @override
  Future<void> delete(HeroId id) async {
    _store.remove(id);
  }

  @override
  Future<List<Hero>> findAll() async {
    return List.unmodifiable(_store.values);
  }
}

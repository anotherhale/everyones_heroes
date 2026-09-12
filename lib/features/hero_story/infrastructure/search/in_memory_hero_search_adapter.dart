import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/hero_search_port.dart';

/// Deterministic in-memory Hero search. Replaceable later.
final class InMemoryHeroSearchAdapter implements HeroSearchPort {
  InMemoryHeroSearchAdapter(this._heroRepository);

  final HeroRepository _heroRepository;

  @override
  Future<List<HeroId>> search(HeroSearchQuery query) async {
    final heroes = await _heroRepository.findAll();

    return heroes
        .where((hero) {
          if (query.activeOnly && hero.status != HeroStatus.active) {
            return false;
          }

          if (query.visibilities.isNotEmpty &&
              !query.visibilities.contains(hero.visibility)) {
            return false;
          }

          if (query.experienceArea != null) {
            final needle = query.experienceArea!.trim().toLowerCase();
            final matches = hero.profile.experienceAreas.any(
              (area) => area.toLowerCase().contains(needle),
            );
            if (!matches) {
              return false;
            }
          }

          if (query.language != null &&
              !hero.profile.languages.contains(query.language)) {
            return false;
          }

          if (query.text != null && query.text!.trim().isNotEmpty) {
            final needle = query.text!.trim().toLowerCase();
            final haystack = [
              hero.profile.displayName,
              hero.profile.biography ?? '',
              ...hero.profile.experienceAreas,
            ].join(' ').toLowerCase();
            if (!haystack.contains(needle)) {
              return false;
            }
          }

          return true;
        })
        .map((hero) => hero.id)
        .toList(growable: false);
  }
}

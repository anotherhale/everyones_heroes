import 'package:everyonesheroes/features/discovery/application/dto/responses/inspiring_hero_summary.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/ensure_current_discovery_profile_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/hero_discoverability_policy.dart';

/// Resolves the current user's inspiring HeroIds for seeker-facing display (D.11).
///
/// ## Flow
///
/// ```text
/// DiscoveryProfile.inspiringHeroIds
///      ↓
/// HeroRepository.findById (per id)
///      ↓
/// HeroDiscoverabilityPolicy
///      ↓
/// InspiringHeroSummary[] (discoverable only)
/// ```
///
/// Missing or undiscoverable Heroes are skipped at read time.
/// Their HeroIds remain on DiscoveryProfile (no silent removal).
///
/// Does **not** mutate DiscoveryProfile.
/// Does **not** affect adaptive ranking.
final class ListInspiringHeroesUseCase {
  ListInspiringHeroesUseCase({
    required this._ensureCurrentDiscoveryProfile,
    required this._heroRepository,
  });

  final EnsureCurrentDiscoveryProfileUseCase _ensureCurrentDiscoveryProfile;
  final HeroRepository _heroRepository;

  Future<List<InspiringHeroSummary>> execute() async {
    final profile = await _ensureCurrentDiscoveryProfile.execute();
    final results = <InspiringHeroSummary>[];

    for (final heroId in profile.inspiringHeroIds) {
      final hero = await _heroRepository.findById(heroId);
      if (hero == null) {
        continue;
      }
      if (!HeroDiscoverabilityPolicy.isDiscoverable(hero)) {
        continue;
      }
      results.add(
        InspiringHeroSummary(
          heroId: hero.id,
          displayName: hero.profile.displayName,
          biography: hero.profile.biography,
        ),
      );
    }

    return List.unmodifiable(results);
  }
}

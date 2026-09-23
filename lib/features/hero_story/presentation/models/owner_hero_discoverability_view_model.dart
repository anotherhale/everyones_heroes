import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';

/// Owner-facing presentation of Hero catalog discoverability (HS.FG.3).
///
/// Maps canonical [HeroVisibility] into Private / Discoverable without
/// exposing [HeroDiscoverabilityPolicy] to presentation.
final class OwnerHeroDiscoverabilityViewModel {
  const OwnerHeroDiscoverabilityViewModel({
    required this.heroId,
    required this.displayName,
    required this.visibility,
    required this.isDiscoverable,
  });

  factory OwnerHeroDiscoverabilityViewModel.fromHero(Hero hero) {
    return OwnerHeroDiscoverabilityViewModel(
      heroId: hero.id,
      displayName: hero.profile.displayName,
      visibility: hero.visibility,
      isDiscoverable: _isDiscoverableVisibility(hero.visibility),
    );
  }

  final HeroId heroId;
  final String displayName;
  final HeroVisibility visibility;
  final bool isDiscoverable;

  String get statusLabel => isDiscoverable ? 'Discoverable' : 'Private';

  String get statusDescription => isDiscoverable
      ? 'Your Hero and eligible Stories may appear in Discovery.'
      : 'Your Hero and eligible Stories are not discoverable.';

  static bool _isDiscoverableVisibility(HeroVisibility visibility) {
    return visibility == HeroVisibility.public ||
        visibility == HeroVisibility.community;
  }
}

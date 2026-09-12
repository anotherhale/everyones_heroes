import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';

/// Pure eligibility rules for catalog Hero discovery (HS.6 / HS-ADR-043).
///
/// Discoverable visibility is exactly `{public, community}`.
/// Private and unlisted Heroes are never discoverable.
final class HeroDiscoverabilityPolicy {
  const HeroDiscoverabilityPolicy._();

  /// Visibility values allowed in catalog discovery / browse.
  static const Set<HeroVisibility> discoverableVisibilities = {
    HeroVisibility.public,
    HeroVisibility.community,
  };

  static List<HeroVisibility> get discoverableVisibilityList =>
      List.unmodifiable(discoverableVisibilities.toList());

  /// Whether [hero] may appear in seeker-facing discovery results.
  static bool isDiscoverable(Hero hero) {
    if (hero.status != HeroStatus.active) {
      return false;
    }
    if (!discoverableVisibilities.contains(hero.visibility)) {
      return false;
    }
    return true;
  }
}

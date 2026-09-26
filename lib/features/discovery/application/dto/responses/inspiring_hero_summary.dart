import 'package:everyonesheroes/core/ids/hero_id.dart';

/// Seeker-facing projection of an inspiring Hero (D.11).
///
/// Hero facts remain owned by Hero & Story; this DTO is a read projection only.
/// Only currently discoverable Heroes are returned by
/// [ListInspiringHeroesUseCase]. Unresolved / undiscoverable IDs are omitted
/// from the list without mutating DiscoveryProfile.
final class InspiringHeroSummary {
  const InspiringHeroSummary({
    required this.heroId,
    required this.displayName,
    this.biography,
  });

  final HeroId heroId;
  final String displayName;
  final String? biography;
}

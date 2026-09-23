import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';

/// Owner request to change a Hero's catalog visibility (HS.FG.3).
///
/// [ownerHeroId] must equal [heroId]. This is the local ownership check until
/// Identity BC exists (HS-ADR-065). Publishing a Story does not use this path.
final class ChangeHeroVisibilityRequest {
  const ChangeHeroVisibilityRequest({
    required this.heroId,
    required this.ownerHeroId,
    required this.visibility,
  });

  final HeroId heroId;

  /// Active owner making the change. Must match [heroId].
  final HeroId ownerHeroId;

  final HeroVisibility visibility;
}

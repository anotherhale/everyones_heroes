import 'package:everyonesheroes/core/ids/hero_id.dart';

/// Owner read of the active Hero (HP.1).
///
/// [heroId] must be the active local Hero identity — not a display-name match
/// and not a seeker discoverability path.
final class GetMyHeroRequest {
  const GetMyHeroRequest({required this.heroId});

  final HeroId heroId;
}

import 'package:everyonesheroes/core/ids/hero_id.dart';

/// Request for discoverability-gated Hero experience detail (HS.7).
final class GetHeroExperienceRequest {
  const GetHeroExperienceRequest({required this.heroId});

  final HeroId heroId;
}

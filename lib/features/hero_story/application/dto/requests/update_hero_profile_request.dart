import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';

final class UpdateHeroProfileRequest {
  const UpdateHeroProfileRequest({
    required this.heroId,
    required this.profile,
  });

  final HeroId heroId;
  final HeroProfile profile;
}

import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/user_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';

final class CreateHeroRequest {
  const CreateHeroRequest({
    required this.heroId,
    required this.profile,
    this.identityUserId,
    this.visibility = HeroVisibility.private,
  });

  final HeroId heroId;
  final HeroProfile profile;
  final UserId? identityUserId;
  final HeroVisibility visibility;
}

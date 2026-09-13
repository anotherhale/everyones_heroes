import 'package:everyonesheroes/features/hero_story/application/dto/responses/hero_experience_detail.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';

/// Projects a discoverable Hero into a safe experience DTO.
final class HeroExperienceMapper {
  const HeroExperienceMapper._();

  static HeroExperienceDetail fromHero(Hero hero) {
    return HeroExperienceDetail(
      heroId: hero.id,
      displayName: hero.profile.displayName,
      biography: hero.profile.biography,
      experienceAreas: List.unmodifiable(hero.profile.experienceAreas),
      languages: List.unmodifiable(hero.profile.languages),
      geographicContext: hero.profile.geographicContext,
      visibility: hero.visibility,
      createdAt: hero.createdAt,
    );
  }
}

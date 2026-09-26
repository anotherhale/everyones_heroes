import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';

/// Owner-facing presentation of the active Hero profile (HP.1 / HP.2).
///
/// Projects the existing [Hero] / [HeroProfile] — not a separate aggregate.
final class MyHeroProfileViewModel {
  const MyHeroProfileViewModel({
    required this.heroId,
    required this.displayName,
    required this.experienceAreas,
    required this.languages,
    required this.visibility,
    this.biography,
    this.geographicContext,
  });

  factory MyHeroProfileViewModel.fromHero(Hero hero) {
    return MyHeroProfileViewModel(
      heroId: hero.id,
      displayName: hero.profile.displayName,
      biography: hero.profile.biography,
      experienceAreas: List.unmodifiable(hero.profile.experienceAreas),
      languages: List.unmodifiable(hero.profile.languages),
      geographicContext: hero.profile.geographicContext,
      visibility: hero.visibility,
    );
  }

  final HeroId heroId;
  final String displayName;
  final String? biography;
  final List<String> experienceAreas;
  final List<LanguageCode> languages;
  final String? geographicContext;
  final HeroVisibility visibility;

  HeroProfile toProfile({
    required String displayName,
    String? biography,
    Iterable<String>? experienceAreas,
    Iterable<LanguageCode>? languages,
    String? geographicContext,
  }) {
    return HeroProfile(
      displayName: displayName,
      biography: biography,
      experienceAreas: experienceAreas ?? this.experienceAreas,
      languages: languages ?? this.languages,
      geographicContext: geographicContext,
    );
  }
}

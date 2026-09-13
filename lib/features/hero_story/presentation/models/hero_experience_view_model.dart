import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/hero_experience_detail.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';

/// Presentation model for Hero Experience (safe DTO projection).
final class HeroExperienceViewModel {
  const HeroExperienceViewModel({
    required this.heroId,
    required this.displayName,
    required this.experienceAreas,
    required this.languages,
    required this.visibilityLabel,
    this.biography,
    this.geographicContext,
  });

  factory HeroExperienceViewModel.fromDetail(HeroExperienceDetail detail) {
    return HeroExperienceViewModel(
      heroId: detail.heroId,
      displayName: detail.displayName,
      biography: detail.biography,
      experienceAreas: detail.experienceAreas,
      languages: detail.languages,
      geographicContext: detail.geographicContext,
      visibilityLabel: _visibilityLabel(detail.visibility),
    );
  }

  final HeroId heroId;
  final String displayName;
  final String? biography;
  final List<String> experienceAreas;
  final List<LanguageCode> languages;
  final String? geographicContext;
  final String visibilityLabel;

  static String _visibilityLabel(HeroVisibility visibility) {
    return switch (visibility) {
      HeroVisibility.public => 'Public',
      HeroVisibility.community => 'Community',
      HeroVisibility.unlisted => 'Unlisted',
      HeroVisibility.private => 'Private',
    };
  }
}

import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';

/// Discoverability-gated Hero experience read model (HS.7 / HS-ADR-049).
///
/// Safe presentation projection — never a raw Hero aggregate.
final class HeroExperienceDetail {
  const HeroExperienceDetail({
    required this.heroId,
    required this.displayName,
    required this.experienceAreas,
    required this.languages,
    required this.visibility,
    required this.createdAt,
    this.biography,
    this.geographicContext,
  });

  final HeroId heroId;
  final String displayName;
  final String? biography;
  final List<String> experienceAreas;
  final List<LanguageCode> languages;
  final String? geographicContext;
  final HeroVisibility visibility;
  final DateTime createdAt;
}

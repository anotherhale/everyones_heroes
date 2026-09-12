import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/discovery_match_reason.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';

/// Safe catalog discovery projection for a Hero (HS-ADR-047).
final class HeroDiscoverySummary {
  const HeroDiscoverySummary({
    required this.heroId,
    required this.displayName,
    required this.experienceAreas,
    required this.languages,
    required this.visibility,
    required this.createdAt,
    required this.matchReasons,
    this.biography,
  });

  final HeroId heroId;
  final String displayName;
  final String? biography;
  final List<String> experienceAreas;
  final List<LanguageCode> languages;
  final HeroVisibility visibility;
  final DateTime createdAt;
  final List<DiscoveryMatchReason> matchReasons;
}

import 'package:everyonesheroes/core/shared_kernel/language_code.dart';

/// Seeker-facing Hero discovery filters with pagination (HS.6).
final class DiscoverHeroesRequest {
  const DiscoverHeroesRequest({
    this.text,
    this.experienceArea,
    this.language,
    this.limit = 20,
    this.offset = 0,
  });

  final String? text;
  final String? experienceArea;
  final LanguageCode? language;
  final int limit;
  final int offset;
}

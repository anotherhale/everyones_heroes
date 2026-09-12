import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';

/// Replaceable search/discovery contract for Heroes.
abstract interface class HeroSearchPort {
  Future<List<HeroId>> search(HeroSearchQuery query);
}

final class HeroSearchQuery {
  const HeroSearchQuery({
    this.text,
    this.experienceArea,
    this.language,
    this.activeOnly = true,
    this.visibilities = const [],
  });

  final String? text;
  final String? experienceArea;
  final LanguageCode? language;
  final bool activeOnly;

  /// When non-empty, Hero visibility must be one of these values.
  final List<HeroVisibility> visibilities;
}

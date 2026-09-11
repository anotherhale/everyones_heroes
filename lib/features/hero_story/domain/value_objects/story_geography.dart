import 'package:everyonesheroes/core/shared_kernel/value_object.dart';

/// Geographic / cultural context of a Story (not Hero current location).
final class StoryGeography extends ValueObject {
  StoryGeography({
    String? country,
    String? region,
    String? city,
    String? culturalContext,
  }) : country = _normalize(country),
       region = _normalize(region),
       city = _normalize(city),
       culturalContext = _normalize(culturalContext) {
    if (this.country == null &&
        this.region == null &&
        this.city == null &&
        this.culturalContext == null) {
      throw ArgumentError(
        'Story geography requires at least one location or cultural context.',
      );
    }
  }

  final String? country;
  final String? region;
  final String? city;
  final String? culturalContext;

  static String? _normalize(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  List<Object?> get equalityProps => [country, region, city, culturalContext];
}

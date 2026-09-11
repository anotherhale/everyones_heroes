import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/core/shared_kernel/value_object.dart';

/// Factual public profile claims about a Hero.
///
/// Must not encode psychological or behavioral interpretations.
final class HeroProfile extends ValueObject {
  HeroProfile({
    required String displayName,
    String? biography,
    Iterable<String>? experienceAreas,
    Iterable<LanguageCode>? languages,
    String? geographicContext,
  }) : displayName = displayName.trim(),
       biography = _normalizeOptional(biography),
       experienceAreas = List.unmodifiable(
         (experienceAreas ?? const <String>[])
             .map((area) => area.trim())
             .where((area) => area.isNotEmpty)
             .toSet()
             .toList(),
       ),
       languages = List.unmodifiable(
         (languages ?? const <LanguageCode>[]).toSet().toList(),
       ),
       geographicContext = _normalizeOptional(geographicContext) {
    if (this.displayName.isEmpty) {
      throw ArgumentError('Hero display name cannot be empty.');
    }

    if (this.displayName.length > 200) {
      throw ArgumentError('Hero display name cannot exceed 200 characters.');
    }

    if (this.biography != null && this.biography!.length > 5000) {
      throw ArgumentError('Hero biography cannot exceed 5000 characters.');
    }
  }

  final String displayName;
  final String? biography;
  final List<String> experienceAreas;
  final List<LanguageCode> languages;
  final String? geographicContext;

  static String? _normalizeOptional(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  HeroProfile copyWith({
    String? displayName,
    String? biography,
    Iterable<String>? experienceAreas,
    Iterable<LanguageCode>? languages,
    String? geographicContext,
    bool clearBiography = false,
    bool clearGeographicContext = false,
  }) {
    return HeroProfile(
      displayName: displayName ?? this.displayName,
      biography: clearBiography ? null : (biography ?? this.biography),
      experienceAreas: experienceAreas ?? this.experienceAreas,
      languages: languages ?? this.languages,
      geographicContext: clearGeographicContext
          ? null
          : (geographicContext ?? this.geographicContext),
    );
  }

  @override
  List<Object?> get equalityProps => [
    displayName,
    biography,
    ...experienceAreas,
    ...languages,
    geographicContext,
  ];
}

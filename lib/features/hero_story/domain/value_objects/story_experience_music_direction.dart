import 'package:everyonesheroes/core/shared_kernel/value_object.dart';

/// Music guidance for a Story Experience Plan (HS.12.4).
///
/// Descriptive direction only — never generated audio, stems, or mixes.
/// [rationale] must be grounded in the captured story/reading and must not
/// make psychological claims.
final class StoryExperienceMusicDirection extends ValueObject {
  StoryExperienceMusicDirection({
    required String mood,
    required String energy,
    required String style,
    required String rationale,
  })  : mood = mood.trim(),
        energy = energy.trim(),
        style = style.trim(),
        rationale = rationale.trim() {
    if (this.mood.isEmpty) {
      throw ArgumentError('musicDirection.mood cannot be empty.');
    }
    if (this.energy.isEmpty) {
      throw ArgumentError('musicDirection.energy cannot be empty.');
    }
    if (this.style.isEmpty) {
      throw ArgumentError('musicDirection.style cannot be empty.');
    }
    if (this.rationale.isEmpty) {
      throw ArgumentError('musicDirection.rationale cannot be empty.');
    }
    if (this.mood.length > maxFieldLength ||
        this.energy.length > maxFieldLength ||
        this.style.length > maxFieldLength) {
      throw ArgumentError(
        'musicDirection mood/energy/style exceed $maxFieldLength characters.',
      );
    }
    if (this.rationale.length > maxRationaleLength) {
      throw ArgumentError(
        'musicDirection.rationale exceeds $maxRationaleLength characters.',
      );
    }
  }

  static const int maxFieldLength = 80;
  static const int maxRationaleLength = 500;

  final String mood;
  final String energy;
  final String style;
  final String rationale;

  @override
  List<Object?> get equalityProps => [mood, energy, style, rationale];
}

import 'package:everyonesheroes/core/shared_kernel/value_object.dart';

/// Session-local story purpose and theme selections (SB.1 capacity; SB.2 vocabulary).
///
/// Distinct from authoritative [StoryClassification]. Intent remains editable
/// while the session is mutable and does not auto-apply to Story catalog.
final class StoryBuilderIntent extends ValueObject {
  StoryBuilderIntent({
    this.purpose,
    Iterable<String>? themes,
    this.purposeUnsure = false,
    this.themesUnsure = false,
  }) : themes = List.unmodifiable(
         (themes ?? const <String>[])
             .map((t) => t.trim())
             .where((t) => t.isNotEmpty)
             .toList(),
       ) {
    if (purpose != null && purpose!.trim().isEmpty) {
      throw ArgumentError('Purpose cannot be blank when provided.');
    }
  }

  /// Empty intent — purpose/themes not yet chosen.
  factory StoryBuilderIntent.empty() => StoryBuilderIntent();

  /// Free-form or future catalog key for why the Hero is telling this story.
  final String? purpose;

  /// Session-local theme labels (not Discovery NarrativeTheme entities).
  final List<String> themes;

  final bool purposeUnsure;
  final bool themesUnsure;

  bool get hasPurpose =>
      purposeUnsure || (purpose != null && purpose!.trim().isNotEmpty);

  bool get hasThemes => themesUnsure || themes.isNotEmpty;

  StoryBuilderIntent copyWith({
    String? purpose,
    Iterable<String>? themes,
    bool? purposeUnsure,
    bool? themesUnsure,
    bool clearPurpose = false,
  }) {
    return StoryBuilderIntent(
      purpose: clearPurpose ? null : (purpose ?? this.purpose),
      themes: themes ?? this.themes,
      purposeUnsure: purposeUnsure ?? this.purposeUnsure,
      themesUnsure: themesUnsure ?? this.themesUnsure,
    );
  }

  @override
  List<Object?> get equalityProps => [
    purpose,
    themes,
    purposeUnsure,
    themesUnsure,
  ];
}

import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_purpose.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_theme.dart';

/// Session-local story purpose and theme selections for Story Builder.
///
/// Purpose (why) and themes (what kind) are independent dimensions.
/// Themes remain Builder intent here; Discovery [NarrativeThemeId] references
/// are applied at materialization via the HS.FG.2 application bridge.
final class StoryBuilderIntent extends ValueObject {
  StoryBuilderIntent({
    this.purpose,
    Iterable<StoryBuilderTheme>? themes,
    this.themesUnsure = false,
  }) : themes = List.unmodifiable(_normalizeThemes(themes)) {
    if (themesUnsure && this.themes.isNotEmpty) {
      throw ArgumentError(
        'themesUnsure cannot be combined with selected themes.',
      );
    }
  }

  /// Empty intent — purpose/themes not yet chosen.
  factory StoryBuilderIntent.empty() => StoryBuilderIntent();

  factory StoryBuilderIntent.purposeOnly(StoryBuilderPurpose purpose) {
    return StoryBuilderIntent(purpose: purpose);
  }

  factory StoryBuilderIntent.themesOnly({
    Iterable<StoryBuilderTheme>? themes,
    bool themesUnsure = false,
  }) {
    return StoryBuilderIntent(themes: themes, themesUnsure: themesUnsure);
  }

  /// Why the Hero is telling this story. `null` = not yet selected.
  /// [StoryBuilderPurpose.notSureYet] = intentional uncertainty.
  final StoryBuilderPurpose? purpose;

  /// Zero or more story themes/types. Order is insertion order after dedupe.
  final List<StoryBuilderTheme> themes;

  /// Explicit "not sure yet" for themes (mutually exclusive with [themes]).
  final bool themesUnsure;

  bool get hasPurpose => purpose != null;

  bool get hasThemes => themesUnsure || themes.isNotEmpty;

  bool get isPurposeUnsure => purpose == StoryBuilderPurpose.notSureYet;

  StoryBuilderIntent withPurpose(StoryBuilderPurpose? purpose) {
    return StoryBuilderIntent(
      purpose: purpose,
      themes: themes,
      themesUnsure: themesUnsure,
    );
  }

  StoryBuilderIntent withThemes({
    Iterable<StoryBuilderTheme>? themes,
    bool? themesUnsure,
  }) {
    return StoryBuilderIntent(
      purpose: purpose,
      themes: themes ?? this.themes,
      themesUnsure: themesUnsure ?? this.themesUnsure,
    );
  }

  StoryBuilderIntent withThemesUnsure() {
    return StoryBuilderIntent(
      purpose: purpose,
      themes: const [],
      themesUnsure: true,
    );
  }

  StoryBuilderIntent copyWith({
    StoryBuilderPurpose? purpose,
    Iterable<StoryBuilderTheme>? themes,
    bool? themesUnsure,
    bool clearPurpose = false,
    bool clearThemes = false,
  }) {
    return StoryBuilderIntent(
      purpose: clearPurpose ? null : (purpose ?? this.purpose),
      themes: clearThemes ? const [] : (themes ?? this.themes),
      themesUnsure: clearThemes ? false : (themesUnsure ?? this.themesUnsure),
    );
  }

  static List<StoryBuilderTheme> _normalizeThemes(
    Iterable<StoryBuilderTheme>? themes,
  ) {
    if (themes == null) {
      return const [];
    }
    final seen = <StoryBuilderTheme>{};
    final result = <StoryBuilderTheme>[];
    for (final theme in themes) {
      if (seen.add(theme)) {
        result.add(theme);
      }
    }
    return result;
  }

  @override
  List<Object?> get equalityProps => [
    purpose,
    themesUnsure,
    ...themes,
  ];
}

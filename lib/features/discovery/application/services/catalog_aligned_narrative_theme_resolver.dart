import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_reference_ids.dart';
import 'package:everyonesheroes/features/discovery/domain/catalog/narrative_theme_reference_catalog.dart';
import 'package:everyonesheroes/features/discovery/domain/entities/narrative_theme.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';
import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/choice_response.dart';
import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/journal_response.dart';
import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/prompt_response.dart';
import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/reflection_response.dart';
import 'package:everyonesheroes/features/life_journey/domain/services/narrative_theme_resolver.dart';

/// Discovery catalog-aligned [NarrativeThemeResolver] (J.2 + Slice B + Slice C).
///
/// Emits only IDs from [NarrativeThemeReferenceIds].
///
/// ## Mapping (deterministic, content-aware)
///
/// Resolves themes by matching normalized reflection response text against
/// catalog phrases in this per-theme order:
///
/// 1. Whole catalog **name** phrase
/// 2. Whole catalog **description** phrase
/// 3. Whole catalog **alias** phrase
///
/// Matching is case-insensitive and punctuation-tolerant (punctuation becomes
/// whitespace; whitespace is collapsed). Phrases must match as whole phrases
/// (`\b…\b`) so `"courage"` does not match `"discourage"` and `"service"` does
/// not match `"serviced"`.
///
/// Multiple matching themes are preserved in **catalog order** (existing
/// Slice B tie rule). When no phrase matches, falls back to
/// [NarrativeThemeReferenceIds.discovery].
///
/// Does not use AI. Does not invent non-catalog IDs. Does not select Stories.
final class CatalogAlignedNarrativeThemeResolver
    implements NarrativeThemeResolver {
  const CatalogAlignedNarrativeThemeResolver();

  /// Legacy Fake ID — aligned to catalog `discovery`.
  static const String legacySelfDiscoveryValue = 'self-discovery';

  @override
  Future<List<NarrativeThemeId>> resolveThemes(Reflection reflection) async {
    final haystack = _collectResponseText(reflection);
    if (haystack.isEmpty) {
      return const [NarrativeThemeReferenceIds.discovery];
    }

    final matched = <NarrativeThemeId>[];
    for (final theme in NarrativeThemeReferenceCatalog.themes) {
      if (_themeMatches(haystack, theme)) {
        matched.add(theme.id);
      }
    }

    if (matched.isEmpty) {
      return const [NarrativeThemeReferenceIds.discovery];
    }

    return List.unmodifiable(matched);
  }

  static bool _themeMatches(String haystack, NarrativeTheme theme) {
    if (_containsPhrase(haystack, theme.name)) {
      return true;
    }
    if (_containsPhrase(haystack, theme.description)) {
      return true;
    }
    for (final alias in theme.aliases) {
      if (_containsPhrase(haystack, alias)) {
        return true;
      }
    }
    return false;
  }

  static String _collectResponseText(Reflection reflection) {
    final parts = <String>[];
    for (final response in reflection.responses) {
      parts.addAll(_textParts(response));
    }
    return _normalize(parts.join(' '));
  }

  static Iterable<String> _textParts(ReflectionResponse response) {
    return switch (response) {
      JournalResponse(:final prompt, :final response) => [
          ?prompt,
          response,
        ],
      PromptResponse(:final prompt, :final response) => [prompt, response],
      ChoiceResponse(:final question, :final selectedOption) => [
          question,
          selectedOption,
        ],
      _ => const <String>[],
    };
  }

  /// Lowercase; strip punctuation to spaces; collapse whitespace.
  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r"[^\w\s']+"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Whole-phrase match so "courage" does not match "discourage".
  static bool _containsPhrase(String haystack, String phrase) {
    final needle = _normalize(phrase);
    if (needle.isEmpty) {
      return false;
    }
    final pattern = RegExp('\\b${RegExp.escape(needle)}\\b');
    return pattern.hasMatch(haystack);
  }
}

import 'package:eh_platform/src/discovery/domain/catalog/narrative_theme_reference_catalog.dart';
import 'package:eh_platform/src/life_journey/domain/aggregates/reflection.dart';
import 'package:eh_platform/src/life_journey/domain/entities/reflection/choice_response.dart';
import 'package:eh_platform/src/life_journey/domain/entities/reflection/journal_response.dart';
import 'package:eh_platform/src/life_journey/domain/entities/reflection/prompt_response.dart';
import 'package:eh_platform/src/life_journey/domain/entities/reflection/reflection_response.dart';
import 'package:eh_platform/src/life_journey/domain/services/narrative_theme_resolver.dart';
import 'package:eh_platform/src/shared_kernel/ids/narrative_theme_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/narrative_theme_reference_ids.dart';

/// Discovery catalog-aligned [NarrativeThemeResolver] (J.2 Slice 2 + Slice B).
///
/// Emits only catalog-valid [NarrativeThemeId]s.
///
/// ## Mapping (deterministic, content-aware)
///
/// Resolves themes by matching reflection response text against catalog theme
/// **names** (case-insensitive whole-phrase). Multiple matches are preserved
/// in catalog order. When no catalog name matches, falls back to
/// [NarrativeThemeReferenceIds.discovery] (prior always-emit behavior).
///
/// Does not use AI. Does not invent non-catalog IDs.
final class CatalogAlignedNarrativeThemeResolver
    implements NarrativeThemeResolver {
  const CatalogAlignedNarrativeThemeResolver();

  @override
  Future<List<NarrativeThemeId>> resolveThemes(Reflection reflection) async {
    final haystack = _collectResponseText(reflection);
    if (haystack.isEmpty) {
      return const [NarrativeThemeReferenceIds.discovery];
    }

    final matched = <NarrativeThemeId>[];
    for (final theme in NarrativeThemeReferenceCatalog.themes) {
      if (_containsPhrase(haystack, theme.name)) {
        matched.add(theme.id);
      }
    }

    if (matched.isEmpty) {
      return const [NarrativeThemeReferenceIds.discovery];
    }

    return List.unmodifiable(matched);
  }

  static String _collectResponseText(Reflection reflection) {
    final parts = <String>[];
    for (final response in reflection.responses) {
      parts.addAll(_textParts(response));
    }
    return parts.join(' ').toLowerCase();
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

  /// Whole-phrase match so "courage" does not match "discourage".
  static bool _containsPhrase(String haystack, String phrase) {
    final needle = phrase.trim().toLowerCase();
    if (needle.isEmpty) {
      return false;
    }
    final pattern = RegExp('\\b${RegExp.escape(needle)}\\b');
    return pattern.hasMatch(haystack);
  }
}

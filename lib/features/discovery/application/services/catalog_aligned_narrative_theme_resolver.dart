import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_reference_ids.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';
import 'package:everyonesheroes/features/life_journey/domain/services/narrative_theme_resolver.dart';

/// Discovery catalog-aligned NarrativeThemeResolver (J.2 Slice 2).
///
/// Replaces production [FakeNarrativeThemeResolver] which emitted
/// non-catalog `self-discovery`. Emits only IDs from
/// [NarrativeThemeReferenceIds].
///
/// ## Mapping (deterministic, transitional)
///
/// Preserves the previous always-emit behavior, mapped to catalog
/// [NarrativeThemeReferenceIds.discovery]. Does not classify reflection
/// content against the full 14-theme vocabulary.
final class CatalogAlignedNarrativeThemeResolver
    implements NarrativeThemeResolver {
  const CatalogAlignedNarrativeThemeResolver();

  /// Legacy Fake ID — aligned to catalog `discovery`.
  static const String legacySelfDiscoveryValue = 'self-discovery';

  @override
  Future<List<NarrativeThemeId>> resolveThemes(Reflection reflection) async {
    return const [NarrativeThemeReferenceIds.discovery];
  }
}

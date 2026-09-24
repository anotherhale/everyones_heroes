import 'package:eh_platform/src/life_journey/domain/aggregates/reflection.dart';
import 'package:eh_platform/src/life_journey/domain/services/narrative_theme_resolver.dart';
import 'package:eh_platform/src/shared_kernel/ids/narrative_theme_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/narrative_theme_reference_ids.dart';

/// Discovery-owned replacement for FakeNarrativeThemeResolver (J.2 Slice 2).
///
/// Emits only catalog-valid [NarrativeThemeId]s.
///
/// ## Mapping (deterministic, transitional)
///
/// The previous Fake always emitted `self-discovery` for every analyzed
/// reflection, regardless of response content. That ID is outside the 14-theme
/// Discovery catalog and cannot overlap with catalog-aligned Story themes.
///
/// This resolver preserves the same always-on deterministic behavior but maps
/// that semantic intent to catalog [NarrativeThemeReferenceIds.discovery]
/// ("Finding meaning, identity, or direction.").
///
/// ## Explicit limitation
///
/// Does **not** classify reflection content against the full 14-theme
/// vocabulary. A content-aware deterministic mapper (or AI behind a port) is
/// deferred; document rather than invent sophistication in J.2.
final class CatalogAlignedNarrativeThemeResolver
    implements NarrativeThemeResolver {
  const CatalogAlignedNarrativeThemeResolver();

  @override
  Future<List<NarrativeThemeId>> resolveThemes(Reflection reflection) async {
    return const [NarrativeThemeReferenceIds.discovery];
  }
}

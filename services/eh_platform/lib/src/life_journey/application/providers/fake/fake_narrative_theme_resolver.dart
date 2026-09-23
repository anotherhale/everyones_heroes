import 'package:eh_platform/src/discovery/application/services/catalog_aligned_narrative_theme_resolver.dart';
import 'package:eh_platform/src/life_journey/domain/aggregates/reflection.dart';
import 'package:eh_platform/src/life_journey/domain/services/narrative_theme_resolver.dart';
import 'package:eh_platform/src/shared_kernel/ids/narrative_theme_id.dart';

/// @Deprecated('J.2: use CatalogAlignedNarrativeThemeResolver')
///
/// Retained as a thin alias so transitional imports keep compiling.
/// Previously emitted non-catalog `self-discovery`; now delegates to the
/// catalog-aligned Discovery resolver.
@Deprecated('Use CatalogAlignedNarrativeThemeResolver')
final class FakeNarrativeThemeResolver implements NarrativeThemeResolver {
  const FakeNarrativeThemeResolver();

  static const CatalogAlignedNarrativeThemeResolver _delegate =
      CatalogAlignedNarrativeThemeResolver();

  @override
  Future<List<NarrativeThemeId>> resolveThemes(Reflection reflection) {
    return _delegate.resolveThemes(reflection);
  }
}

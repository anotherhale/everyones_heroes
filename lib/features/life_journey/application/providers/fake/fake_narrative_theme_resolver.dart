import 'package:everyonesheroes/features/discovery/application/services/catalog_aligned_narrative_theme_resolver.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';
import 'package:everyonesheroes/features/life_journey/domain/services/narrative_theme_resolver.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';

/// @Deprecated('J.2: use CatalogAlignedNarrativeThemeResolver')
///
/// Previously emitted non-catalog `self-discovery`. Now delegates to the
/// Discovery catalog-aligned resolver.
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

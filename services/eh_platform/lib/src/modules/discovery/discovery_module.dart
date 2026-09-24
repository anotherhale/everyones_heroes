/// Discovery module boundary (PF-ADR-002 / J.2).
///
/// Owns: NarrativeTheme reference catalog (J.2 Slice 1), catalog-aligned
/// adaptive discovery signal resolution (J.2 Slice 2).
///
/// Deferred (not J.2 Slices 1–3):
/// * DiscoveryProfile authority
/// * Discovery Activities
/// * Influence productization
/// * Public Discovery REST API
///
/// Story candidates are owned by Hero & Story (Slice 3 seed); Discovery owns
/// theme vocabulary only. Other modules reference NarrativeThemeId / catalog
/// IDs only.
library;

import 'package:eh_platform/src/discovery/application/services/catalog_aligned_adaptive_discovery_signal_resolver.dart';
import 'package:eh_platform/src/discovery/application/services/catalog_aligned_narrative_theme_resolver.dart';
import 'package:eh_platform/src/discovery/domain/catalog/narrative_theme_reference_catalog.dart';
import 'package:eh_platform/src/experience/application/ports/adaptive_discovery_signal_port.dart';
import 'package:eh_platform/src/life_journey/domain/repositories/reflection_repository.dart';
import 'package:eh_platform/src/life_journey/domain/services/narrative_theme_resolver.dart';

export 'package:eh_platform/src/discovery/application/services/catalog_aligned_adaptive_discovery_signal_resolver.dart';
export 'package:eh_platform/src/discovery/application/services/catalog_aligned_narrative_theme_resolver.dart';
export 'package:eh_platform/src/discovery/domain/catalog/narrative_theme_reference_catalog.dart';
export 'package:eh_platform/src/discovery/domain/entities/narrative_theme.dart';
export 'package:eh_platform/src/discovery/domain/services/narrative_theme_alignment.dart';
export 'package:eh_platform/src/shared_kernel/ids/narrative_theme_reference_ids.dart';

final class DiscoveryModule {
  const DiscoveryModule();

  static const String name = 'discovery';

  /// Compose Discovery capabilities required by Life Journey + Experience.
  static DiscoveryComponents compose({
    required ReflectionRepository reflectionRepository,
  }) {
    const themeResolver = CatalogAlignedNarrativeThemeResolver();
    final signalResolver = CatalogAlignedAdaptiveDiscoverySignalResolver(
      reflectionRepository: reflectionRepository,
    );
    return DiscoveryComponents(
      narrativeThemeResolver: themeResolver,
      adaptiveDiscoverySignalPort: signalResolver,
      catalogThemeCount: NarrativeThemeReferenceCatalog.themes.length,
    );
  }
}

/// Wired Discovery capabilities for composition / tests.
final class DiscoveryComponents {
  const DiscoveryComponents({
    required this.narrativeThemeResolver,
    required this.adaptiveDiscoverySignalPort,
    required this.catalogThemeCount,
  });

  /// Catalog-aligned [NarrativeThemeResolver] for AnalyzeReflection.
  final NarrativeThemeResolver narrativeThemeResolver;

  /// Catalog-aligned signal port for Experience Selection / HS.8.
  final AdaptiveDiscoverySignalPort adaptiveDiscoverySignalPort;

  final int catalogThemeCount;
}

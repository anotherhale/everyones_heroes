import 'package:eh_platform/src/discovery/domain/catalog/narrative_theme_reference_catalog.dart';
import 'package:eh_platform/src/shared_kernel/ids/narrative_theme_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/narrative_theme_reference_ids.dart';

/// Aligns persisted / resolved theme IDs to the Discovery catalog (J.2 Slice 2).
///
/// Distinguishes:
/// * stored Reflection observations (may include legacy non-catalog IDs)
/// * derived adaptive discovery signals (catalog-valid IDs only)
///
/// Mapping rules (deterministic, non-AI):
/// 1. Catalog members pass through unchanged.
/// 2. Legacy Fake resolver ID `self-discovery` → catalog `discovery`.
/// 3. All other unknown IDs are dropped (never invented).
abstract final class NarrativeThemeAlignment {
  /// Legacy production FakeNarrativeThemeResolver emitted this non-catalog ID.
  static const String legacySelfDiscoveryValue = 'self-discovery';

  /// Returns a catalog-valid ID, or `null` when the input cannot be aligned.
  static NarrativeThemeId? align(NarrativeThemeId id) {
    if (NarrativeThemeReferenceCatalog.contains(id)) {
      return id;
    }
    if (id.value == legacySelfDiscoveryValue) {
      return NarrativeThemeReferenceIds.discovery;
    }
    return null;
  }

  /// Aligns, deduplicates, and sorts by opaque ID value for determinism.
  static List<NarrativeThemeId> alignAll(Iterable<NarrativeThemeId> ids) {
    final byValue = <String, NarrativeThemeId>{};
    for (final id in ids) {
      final aligned = align(id);
      if (aligned == null) continue;
      byValue.putIfAbsent(aligned.value, () => aligned);
    }
    final sorted = byValue.keys.toList()..sort();
    return [for (final value in sorted) byValue[value]!];
  }

  /// Aligns opaque string theme IDs (e.g. from AdaptiveDiscoverySignals DTOs).
  static List<String> alignValues(Iterable<String> values) {
    return alignAll(values.map(NarrativeThemeId.new))
        .map((id) => id.value)
        .toList(growable: false);
  }
}

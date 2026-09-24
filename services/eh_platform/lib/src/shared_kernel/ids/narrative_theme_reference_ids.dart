import 'package:eh_platform/src/shared_kernel/ids/narrative_theme_id.dart';

/// Stable cross-context [NarrativeThemeId] reference values.
///
/// These opaque string IDs are the shared contract other contexts use to
/// reference Discovery-owned NarrativeTheme entities. Display labels are
/// not IDs — names/descriptions live on Discovery's reference catalog.
///
/// Ownership of NarrativeTheme entities remains in Discovery (J.2).
/// Mirrors Flutter `NarrativeThemeReferenceIds` — do not expand casually.
abstract final class NarrativeThemeReferenceIds {
  static const NarrativeThemeId overcomingAdversity =
      NarrativeThemeId('overcoming-adversity');
  static const NarrativeThemeId courage = NarrativeThemeId('courage');
  static const NarrativeThemeId service = NarrativeThemeId('service');
  static const NarrativeThemeId leadership = NarrativeThemeId('leadership');
  static const NarrativeThemeId loss = NarrativeThemeId('loss');
  static const NarrativeThemeId failure = NarrativeThemeId('failure');
  static const NarrativeThemeId transformation =
      NarrativeThemeId('transformation');
  static const NarrativeThemeId perseverance =
      NarrativeThemeId('perseverance');
  static const NarrativeThemeId secondChances =
      NarrativeThemeId('second-chances');
  static const NarrativeThemeId sacrifice = NarrativeThemeId('sacrifice');
  static const NarrativeThemeId family = NarrativeThemeId('family');
  static const NarrativeThemeId discovery = NarrativeThemeId('discovery');
  static const NarrativeThemeId purpose = NarrativeThemeId('purpose');
  static const NarrativeThemeId love = NarrativeThemeId('love');

  /// All currently seeded Discovery reference theme IDs (exactly 14).
  static const List<NarrativeThemeId> all = [
    overcomingAdversity,
    courage,
    service,
    leadership,
    loss,
    failure,
    transformation,
    perseverance,
    secondChances,
    sacrifice,
    family,
    discovery,
    purpose,
    love,
  ];

  static final Set<String> _values = {for (final id in all) id.value};

  /// Whether [id] is a member of the canonical Discovery catalog.
  static bool contains(NarrativeThemeId id) => _values.contains(id.value);

  /// Whether the opaque string value is a member of the catalog.
  static bool containsValue(String value) => _values.contains(value);
}

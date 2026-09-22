import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';

/// Stable Discovery-owned [NarrativeThemeId] reference values.
///
/// Ownership: Discovery. Other contexts may reference these IDs; they must not
/// redefine NarrativeTheme entities or invent parallel taxonomies.
///
/// Values are opaque stable strings (not display labels). Presentation labels
/// live on [NarrativeTheme.name] in the reference catalog.
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

  /// All currently seeded Discovery reference theme IDs.
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
}

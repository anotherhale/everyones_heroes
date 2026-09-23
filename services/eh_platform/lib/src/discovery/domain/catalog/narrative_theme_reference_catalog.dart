import 'package:eh_platform/src/discovery/domain/entities/narrative_theme.dart';
import 'package:eh_platform/src/shared_kernel/ids/narrative_theme_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/narrative_theme_reference_ids.dart';

/// Discovery-owned code-defined NarrativeTheme reference catalog (J.2 Slice 1).
///
/// Authoritative vocabulary for platform adaptive discovery signals and
/// theme-overlap seams. Matches Flutter's 14-theme Discovery catalog exactly.
///
/// Storage decision: code-defined seed (not SQL). Reference vocabulary needs
/// stable IDs, deterministic availability, and testability without migration
/// machinery. SQL catalog tables remain a D.1 option if productization needs
/// runtime edits — not required for J.2 Slices 1–2.
abstract final class NarrativeThemeReferenceCatalog {
  static List<NarrativeTheme> get themes => List.unmodifiable(_themes);

  static NarrativeTheme? findById(NarrativeThemeId id) => _byId[id.value];

  static bool contains(NarrativeThemeId id) =>
      NarrativeThemeReferenceIds.contains(id);

  static final Map<String, NarrativeTheme> _byId = {
    for (final theme in _themes) theme.id.value: theme,
  };

  static final List<NarrativeTheme> _themes = [
    NarrativeTheme(
      id: NarrativeThemeReferenceIds.overcomingAdversity,
      name: 'Overcoming adversity',
      description: 'Facing hardship and continuing forward.',
    ),
    NarrativeTheme(
      id: NarrativeThemeReferenceIds.courage,
      name: 'Courage',
      description: 'Acting despite fear.',
    ),
    NarrativeTheme(
      id: NarrativeThemeReferenceIds.service,
      name: 'Service',
      description: 'Helping others through lived experience.',
    ),
    NarrativeTheme(
      id: NarrativeThemeReferenceIds.leadership,
      name: 'Leadership',
      description: 'Guiding or taking responsibility for others.',
    ),
    NarrativeTheme(
      id: NarrativeThemeReferenceIds.loss,
      name: 'Loss',
      description: 'Living through loss and its aftermath.',
    ),
    NarrativeTheme(
      id: NarrativeThemeReferenceIds.failure,
      name: 'Failure',
      description: 'Confronting failure and what follows.',
    ),
    NarrativeTheme(
      id: NarrativeThemeReferenceIds.transformation,
      name: 'Transformation',
      description: 'Meaningful personal change over time.',
    ),
    NarrativeTheme(
      id: NarrativeThemeReferenceIds.perseverance,
      name: 'Perseverance',
      description: 'Continuing despite difficulty.',
    ),
    NarrativeTheme(
      id: NarrativeThemeReferenceIds.secondChances,
      name: 'Second chances',
      description: 'Beginning again after a setback.',
    ),
    NarrativeTheme(
      id: NarrativeThemeReferenceIds.sacrifice,
      name: 'Sacrifice',
      description: 'Giving something up for a greater purpose.',
    ),
    NarrativeTheme(
      id: NarrativeThemeReferenceIds.family,
      name: 'Family',
      description: 'Family bonds, responsibility, and belonging.',
    ),
    NarrativeTheme(
      id: NarrativeThemeReferenceIds.discovery,
      name: 'Discovery',
      description: 'Finding meaning, identity, or direction.',
    ),
    NarrativeTheme(
      id: NarrativeThemeReferenceIds.purpose,
      name: 'Purpose',
      description: 'Seeking or living with purpose.',
    ),
    NarrativeTheme(
      id: NarrativeThemeReferenceIds.love,
      name: 'Love',
      description: 'Love as a central narrative force.',
    ),
  ];
}

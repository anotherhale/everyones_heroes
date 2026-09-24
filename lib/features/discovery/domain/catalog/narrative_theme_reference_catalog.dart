import 'package:everyonesheroes/core/ids/narrative_theme_reference_ids.dart';
import 'package:everyonesheroes/features/discovery/domain/entities/narrative_theme.dart';

/// Discovery-owned seed/reference NarrativeTheme catalog.
///
/// Establishes stable [NarrativeTheme] entities for cross-context reference
/// using shared-kernel [NarrativeThemeReferenceIds].
/// Does not personalize; does not infer Hero preferences.
///
/// ## Alias phrases
///
/// Optional [NarrativeTheme.aliases] are catalog-owned whole phrases drawn
/// from existing description language (not invented synonyms). They enable
/// deterministic phrase alignment when reflection text does not contain the
/// display [NarrativeTheme.name].
abstract final class NarrativeThemeReferenceCatalog {
  static List<NarrativeTheme> get themes => List.unmodifiable(_themes);

  static final List<NarrativeTheme> _themes = [
    NarrativeTheme(
      id: NarrativeThemeReferenceIds.overcomingAdversity,
      name: 'Overcoming adversity',
      description: 'Facing hardship and continuing forward.',
      aliases: const ['facing hardship and continuing forward'],
    ),
    NarrativeTheme(
      id: NarrativeThemeReferenceIds.courage,
      name: 'Courage',
      description: 'Acting despite fear.',
      aliases: const ['acting despite fear'],
    ),
    NarrativeTheme(
      id: NarrativeThemeReferenceIds.service,
      name: 'Service',
      description: 'Helping others through lived experience.',
      aliases: const ['helping others through lived experience'],
    ),
    NarrativeTheme(
      id: NarrativeThemeReferenceIds.leadership,
      name: 'Leadership',
      description: 'Guiding or taking responsibility for others.',
      aliases: const ['taking responsibility for others'],
    ),
    NarrativeTheme(
      id: NarrativeThemeReferenceIds.loss,
      name: 'Loss',
      description: 'Living through loss and its aftermath.',
      aliases: const ['living through loss and its aftermath'],
    ),
    NarrativeTheme(
      id: NarrativeThemeReferenceIds.failure,
      name: 'Failure',
      description: 'Confronting failure and what follows.',
      aliases: const ['confronting failure and what follows'],
    ),
    NarrativeTheme(
      id: NarrativeThemeReferenceIds.transformation,
      name: 'Transformation',
      description: 'Meaningful personal change over time.',
      aliases: const ['personal change over time'],
    ),
    NarrativeTheme(
      id: NarrativeThemeReferenceIds.perseverance,
      name: 'Perseverance',
      description: 'Continuing despite difficulty.',
      aliases: const ['continuing despite difficulty'],
    ),
    NarrativeTheme(
      id: NarrativeThemeReferenceIds.secondChances,
      name: 'Second chances',
      description: 'Beginning again after a setback.',
      aliases: const ['beginning again after a setback'],
    ),
    NarrativeTheme(
      id: NarrativeThemeReferenceIds.sacrifice,
      name: 'Sacrifice',
      description: 'Giving something up for a greater purpose.',
      aliases: const ['giving something up for a greater purpose'],
    ),
    NarrativeTheme(
      id: NarrativeThemeReferenceIds.family,
      name: 'Family',
      description: 'Family bonds, responsibility, and belonging.',
      aliases: const ['family bonds, responsibility, and belonging'],
    ),
    NarrativeTheme(
      id: NarrativeThemeReferenceIds.discovery,
      name: 'Discovery',
      description: 'Finding meaning, identity, or direction.',
      aliases: const ['finding meaning'],
    ),
    NarrativeTheme(
      id: NarrativeThemeReferenceIds.purpose,
      name: 'Purpose',
      description: 'Seeking or living with purpose.',
      aliases: const ['seeking or living with purpose'],
    ),
    NarrativeTheme(
      id: NarrativeThemeReferenceIds.love,
      name: 'Love',
      description: 'Love as a central narrative force.',
      aliases: const ['central narrative force'],
    ),
  ];
}

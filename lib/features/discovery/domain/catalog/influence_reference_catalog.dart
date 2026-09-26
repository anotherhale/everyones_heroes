import 'package:everyonesheroes/core/ids/influence_reference_ids.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_reference_ids.dart';
import 'package:everyonesheroes/features/discovery/domain/entities/influence.dart';
import 'package:everyonesheroes/features/discovery/domain/enums/influence_category.dart';

/// Discovery-owned curated Influence seed catalog (D.3).
///
/// Small, deliberate set of Influences mapped to existing
/// [NarrativeThemeReferenceIds] only. Does not invent a second theme
/// vocabulary. Does not create Hero aggregate relationships.
///
/// Catalog Influences are canonical inspiration primitives.
/// User selections live on [DiscoveryProfile] as [InfluenceId] references.
abstract final class InfluenceReferenceCatalog {
  static List<Influence> get influences => List.unmodifiable(_influences);

  static final List<Influence> _influences = [
    Influence(
      id: InfluenceReferenceIds.rockyBalboa,
      canonicalName: 'Rocky Balboa',
      category: InfluenceCategory.character,
      aliases: const ['Rocky'],
      description:
          'A fictional boxer whose perseverance and courage inspire others.',
      narrativeThemeIds: const [
        NarrativeThemeReferenceIds.perseverance,
        NarrativeThemeReferenceIds.overcomingAdversity,
        NarrativeThemeReferenceIds.courage,
      ],
    ),
    Influence(
      id: InfluenceReferenceIds.davidGoggins,
      canonicalName: 'David Goggins',
      category: InfluenceCategory.militaryHero,
      description:
          'Former Navy SEAL known for discipline and mental toughness.',
      narrativeThemeIds: const [
        NarrativeThemeReferenceIds.perseverance,
        NarrativeThemeReferenceIds.overcomingAdversity,
        NarrativeThemeReferenceIds.purpose,
      ],
    ),
    Influence(
      id: InfluenceReferenceIds.aragorn,
      canonicalName: 'Aragorn',
      category: InfluenceCategory.character,
      description:
          'The rightful king of Gondor who exemplifies leadership and courage.',
      narrativeThemeIds: const [
        NarrativeThemeReferenceIds.leadership,
        NarrativeThemeReferenceIds.courage,
        NarrativeThemeReferenceIds.sacrifice,
      ],
    ),
    Influence(
      id: InfluenceReferenceIds.michaelJordan,
      canonicalName: 'Michael Jordan',
      category: InfluenceCategory.athlete,
      description:
          'Legendary basketball player known for relentless competitiveness.',
      narrativeThemeIds: const [
        NarrativeThemeReferenceIds.perseverance,
        NarrativeThemeReferenceIds.failure,
        NarrativeThemeReferenceIds.transformation,
      ],
    ),
    Influence(
      id: InfluenceReferenceIds.atomicHabits,
      canonicalName: 'Atomic Habits',
      category: InfluenceCategory.book,
      description:
          'A book about building better habits through small improvements.',
      narrativeThemeIds: const [
        NarrativeThemeReferenceIds.transformation,
        NarrativeThemeReferenceIds.purpose,
        NarrativeThemeReferenceIds.discovery,
      ],
    ),
    Influence(
      id: InfluenceReferenceIds.lordOfTheRings,
      canonicalName: 'The Lord of the Rings',
      category: InfluenceCategory.movie,
      description:
          'An epic fantasy centered on courage, sacrifice, and perseverance.',
      narrativeThemeIds: const [
        NarrativeThemeReferenceIds.courage,
        NarrativeThemeReferenceIds.sacrifice,
        NarrativeThemeReferenceIds.perseverance,
      ],
    ),
    Influence(
      id: InfluenceReferenceIds.navySeals,
      canonicalName: 'United States Navy SEALs',
      category: InfluenceCategory.organization,
      aliases: const ['Navy SEALs'],
      description:
          'Elite special operations force representing discipline and service.',
      narrativeThemeIds: const [
        NarrativeThemeReferenceIds.service,
        NarrativeThemeReferenceIds.leadership,
        NarrativeThemeReferenceIds.sacrifice,
      ],
    ),
    Influence(
      id: InfluenceReferenceIds.malalaYousafzai,
      canonicalName: 'Malala Yousafzai',
      category: InfluenceCategory.historicalFigure,
      description:
          'Advocate for education whose courage inspires purpose and resilience.',
      narrativeThemeIds: const [
        NarrativeThemeReferenceIds.courage,
        NarrativeThemeReferenceIds.purpose,
        NarrativeThemeReferenceIds.overcomingAdversity,
      ],
    ),
    Influence(
      id: InfluenceReferenceIds.nelsonMandela,
      canonicalName: 'Nelson Mandela',
      category: InfluenceCategory.historicalFigure,
      description:
          'Leader whose life embodies second chances and moral leadership.',
      narrativeThemeIds: const [
        NarrativeThemeReferenceIds.leadership,
        NarrativeThemeReferenceIds.secondChances,
        NarrativeThemeReferenceIds.overcomingAdversity,
      ],
    ),
    Influence(
      id: InfluenceReferenceIds.fredRogers,
      canonicalName: 'Fred Rogers',
      category: InfluenceCategory.mentor,
      description:
          'Television host known for kindness, belonging, and quiet service.',
      narrativeThemeIds: const [
        NarrativeThemeReferenceIds.love,
        NarrativeThemeReferenceIds.family,
        NarrativeThemeReferenceIds.service,
      ],
    ),
    Influence(
      id: InfluenceReferenceIds.marieCurie,
      canonicalName: 'Marie Curie',
      category: InfluenceCategory.historicalFigure,
      description:
          'Scientist whose discovery and perseverance opened new paths.',
      narrativeThemeIds: const [
        NarrativeThemeReferenceIds.discovery,
        NarrativeThemeReferenceIds.perseverance,
        NarrativeThemeReferenceIds.purpose,
      ],
    ),
    Influence(
      id: InfluenceReferenceIds.breneBrown,
      canonicalName: 'Brené Brown',
      category: InfluenceCategory.mentor,
      description:
          'Researcher whose work on courage and vulnerability inspires growth.',
      narrativeThemeIds: const [
        NarrativeThemeReferenceIds.courage,
        NarrativeThemeReferenceIds.transformation,
        NarrativeThemeReferenceIds.love,
      ],
    ),
  ];
}

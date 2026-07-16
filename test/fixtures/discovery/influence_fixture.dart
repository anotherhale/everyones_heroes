import 'package:everyonesheroes/core/ids/influence_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/features/discovery/domain/entities/influence.dart';
import 'package:everyonesheroes/features/discovery/domain/enums/influence_category.dart';

final class InfluenceFixture {
  const InfluenceFixture._();

  static Influence create({
    InfluenceId? id,
    required String canonicalName,
    InfluenceCategory category = InfluenceCategory.character,
    Iterable<NarrativeThemeId>? narrativeThemeIds,
    Iterable<String>? aliases,
    String? description,
    String? imageReference,
  }) {
    return Influence(
      id: id ?? InfluenceId.generate(),
      canonicalName: canonicalName,
      category: category,
      narrativeThemeIds: narrativeThemeIds ?? [NarrativeThemeId.generate()],
      aliases: aliases,
      description: description,
      imageReference: imageReference,
    );
  }

  static Influence rocky() => create(
    canonicalName: 'Rocky Balboa',
    category: InfluenceCategory.character,
    aliases: const ['Rocky'],
    description:
        'A fictional boxer whose perseverance, resilience, and determination inspire others.',
  );

  static Influence davidGoggins() => create(
    canonicalName: 'David Goggins',
    category: InfluenceCategory.militaryHero,
    description: 'Former Navy SEAL known for discipline and mental toughness.',
  );

  static Influence aragorn() => create(
    canonicalName: 'Aragorn',
    category: InfluenceCategory.character,
    description:
        'The rightful king of Gondor who exemplifies leadership and courage.',
  );

  static Influence michaelJordan() => create(
    canonicalName: 'Michael Jordan',
    category: InfluenceCategory.athlete,
    description:
        'Legendary basketball player known for relentless competitiveness.',
  );

  static Influence atomicHabits() => create(
    canonicalName: 'Atomic Habits',
    category: InfluenceCategory.book,
    description:
        'A bestselling book about building better habits through small improvements.',
  );

  static Influence lordOfTheRings() => create(
    canonicalName: 'The Lord of the Rings',
    category: InfluenceCategory.movie,
    description:
        'An epic fantasy centered on courage, sacrifice, friendship, and hope.',
  );

  static Influence navySeals() => create(
    canonicalName: 'United States Navy SEALs',
    category: InfluenceCategory.organization,
    aliases: const ['Navy SEALs'],
    description:
        'Elite special operations force representing discipline and service.',
  );
}

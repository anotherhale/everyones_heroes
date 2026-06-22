import 'package:everyonesheroes/core/ids/influence_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';

import 'package:everyonesheroes/features/discovery/domain/entities/influence.dart';
import 'package:everyonesheroes/features/discovery/domain/enums/influence_category.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Influence', () {
    late NarrativeThemeId theme1;
    late NarrativeThemeId theme2;

    setUp(() {
      theme1 = NarrativeThemeId.generate();
      theme2 = NarrativeThemeId.generate();
    });

    test('creates influence', () {
      final influence = Influence(
        id: InfluenceId.generate(),
        canonicalName: 'Rocky',
        category: InfluenceCategory.movie,
        narrativeThemeIds: [theme1],
      );

      expect(influence.canonicalName, 'Rocky');

      expect(influence.category, InfluenceCategory.movie);
    });

    test('requires canonical name', () {
      expect(
        () => Influence(
          id: InfluenceId.generate(),
          canonicalName: '',
          category: InfluenceCategory.movie,
          narrativeThemeIds: [theme1],
        ),
        throwsArgumentError,
      );
    });

    test('requires at least one narrative theme', () {
      expect(
        () => Influence(
          id: InfluenceId.generate(),
          canonicalName: 'Rocky',
          category: InfluenceCategory.movie,
          narrativeThemeIds: const [],
        ),
        throwsArgumentError,
      );
    });

    test('contains theme', () {
      final influence = Influence(
        id: InfluenceId.generate(),
        canonicalName: 'Rocky',
        category: InfluenceCategory.movie,
        narrativeThemeIds: [theme1],
      );

      expect(influence.containsTheme(theme1), isTrue);
    });

    test('matches canonical name', () {
      final influence = Influence(
        id: InfluenceId.generate(),
        canonicalName: 'Rocky',
        category: InfluenceCategory.movie,
        narrativeThemeIds: [theme1],
      );

      expect(influence.matchesName('rocky'), isTrue);
    });

    test('matches alias', () {
      final influence = Influence(
        id: InfluenceId.generate(),
        canonicalName: 'Rocky',
        category: InfluenceCategory.movie,
        aliases: const ['Rocky Balboa'],
        narrativeThemeIds: [theme1],
      );

      expect(influence.matchesName('rocky balboa'), isTrue);
    });

    test('does not match unknown alias', () {
      final influence = Influence(
        id: InfluenceId.generate(),
        canonicalName: 'Rocky',
        category: InfluenceCategory.movie,
        narrativeThemeIds: [theme1],
      );

      expect(influence.matchesName('aragorn'), isFalse);
    });

    test('adds alias', () {
      final influence = Influence(
        id: InfluenceId.generate(),
        canonicalName: 'Rocky',
        category: InfluenceCategory.movie,
        narrativeThemeIds: [theme1],
      );

      influence.addAlias('Balboa');

      expect(influence.aliases, contains('Balboa'));
    });

    test('does not duplicate alias', () {
      final influence = Influence(
        id: InfluenceId.generate(),
        canonicalName: 'Rocky',
        category: InfluenceCategory.movie,
        aliases: const ['Balboa'],
        narrativeThemeIds: [theme1],
      );

      influence.addAlias('Balboa');

      expect(influence.aliases.length, 1);
    });

    test('removes alias', () {
      final influence = Influence(
        id: InfluenceId.generate(),
        canonicalName: 'Rocky',
        category: InfluenceCategory.movie,
        aliases: const ['Balboa'],
        narrativeThemeIds: [theme1],
      );

      influence.removeAlias('Balboa');

      expect(influence.aliases, isEmpty);
    });

    test('adds theme', () {
      final influence = Influence(
        id: InfluenceId.generate(),
        canonicalName: 'Rocky',
        category: InfluenceCategory.movie,
        narrativeThemeIds: [theme1],
      );

      influence.addTheme(theme2);

      expect(influence.narrativeThemeIds.length, 2);
    });

    test('does not duplicate theme', () {
      final influence = Influence(
        id: InfluenceId.generate(),
        canonicalName: 'Rocky',
        category: InfluenceCategory.movie,
        narrativeThemeIds: [theme1],
      );

      influence.addTheme(theme1);

      expect(influence.narrativeThemeIds.length, 1);
    });

    test('removes theme', () {
      final influence = Influence(
        id: InfluenceId.generate(),
        canonicalName: 'Rocky',
        category: InfluenceCategory.movie,
        narrativeThemeIds: [theme1, theme2],
      );

      influence.removeTheme(theme2);

      expect(influence.narrativeThemeIds.length, 1);
    });

    test('cannot remove last theme', () {
      final influence = Influence(
        id: InfluenceId.generate(),
        canonicalName: 'Rocky',
        category: InfluenceCategory.movie,
        narrativeThemeIds: [theme1],
      );

      expect(() => influence.removeTheme(theme1), throwsStateError);
    });

    test('aliases are immutable', () {
      final influence = Influence(
        id: InfluenceId.generate(),
        canonicalName: 'Rocky',
        category: InfluenceCategory.movie,
        narrativeThemeIds: [theme1],
      );

      expect(() => influence.aliases.add('test'), throwsUnsupportedError);
    });

    test('theme ids are immutable', () {
      final influence = Influence(
        id: InfluenceId.generate(),
        canonicalName: 'Rocky',
        category: InfluenceCategory.movie,
        narrativeThemeIds: [theme1],
      );

      expect(
        () => influence.narrativeThemeIds.add(theme2),
        throwsUnsupportedError,
      );
    });
  });
}

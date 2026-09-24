import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/features/discovery/domain/entities/narrative_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NarrativeTheme', () {
    test('creates theme', () {
      final theme = NarrativeTheme(
        id: NarrativeThemeId.generate(),
        name: 'Perseverance',
        description: 'Continuing despite difficulty.',
      );

      expect(theme.name, 'Perseverance');

      expect(theme.description, 'Continuing despite difficulty.');
    });

    test('requires name', () {
      expect(
        () => NarrativeTheme(
          id: NarrativeThemeId.generate(),
          name: '',
          description: 'Description',
        ),
        throwsArgumentError,
      );
    });

    test('trims name', () {
      final theme = NarrativeTheme(
        id: NarrativeThemeId.generate(),
        name: '  Courage  ',
        description: 'Description',
      );

      expect(theme.name, 'Courage');
    });

    test('inherits entity identity', () {
      final id = NarrativeThemeId.generate();

      final theme = NarrativeTheme(
        id: id,
        name: 'Service',
        description: 'Helping others.',
      );

      expect(theme.id, id);
    });

    test('exposes optional aliases', () {
      final theme = NarrativeTheme(
        id: NarrativeThemeId.generate(),
        name: 'Leadership',
        description: 'Guiding or taking responsibility for others.',
        aliases: const ['taking responsibility for others', '  '],
      );

      expect(theme.aliases, ['taking responsibility for others']);
    });

    test('defaults aliases to empty', () {
      final theme = NarrativeTheme(
        id: NarrativeThemeId.generate(),
        name: 'Courage',
        description: 'Acting despite fear.',
      );

      expect(theme.aliases, isEmpty);
    });
  });
}

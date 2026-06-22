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
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/features/life_journey/domain/value_objects/mission_title.dart';

void main() {
  group('MissionTitle', () {
    test('creates valid title', () {
      final title = MissionTitle(
        'Walk for 20 minutes',
      );

      expect(
        title.value,
        'Walk for 20 minutes',
      );
    });

    test('trims whitespace', () {
      final title = MissionTitle(
        '   Walk for 20 minutes   ',
      );

      expect(
        title.value,
        'Walk for 20 minutes',
      );
    });

    test('throws when empty', () {
      expect(
        () => MissionTitle(''),
        throwsArgumentError,
      );
    });

    test('throws when whitespace only', () {
      expect(
        () => MissionTitle('    '),
        throwsArgumentError,
      );
    });

    test('throws when longer than 100 characters', () {
      expect(
        () => MissionTitle('a' * 101),
        throwsArgumentError,
      );
    });

    test('allows exactly 100 characters', () {
      expect(
        () => MissionTitle('a' * 100),
        returnsNormally,
      );
    });

    test('equal when values match', () {
      expect(
        MissionTitle('Mission'),
        equals(
          MissionTitle('Mission'),
        ),
      );
    });

    test('not equal when values differ', () {
      expect(
        MissionTitle('Mission A'),
        isNot(
          equals(
            MissionTitle('Mission B'),
          ),
        ),
      );
    });

    test('hashCodes match for equal values', () {
      expect(
        MissionTitle('Mission').hashCode,
        MissionTitle('Mission').hashCode,
      );
    });

    test('toString returns title value', () {
      expect(
        MissionTitle('Mission').toString(),
        'Mission',
      );
    });
  });
}
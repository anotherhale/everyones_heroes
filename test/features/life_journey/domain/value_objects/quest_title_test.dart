import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/features/life_journey/domain/value_objects/quest_title.dart';

void main() {
  group('QuestTitle', () {
    test('creates valid title', () {
      final title = QuestTitle(
        '90 Day Weight Loss Quest',
      );

      expect(
        title.value,
        '90 Day Weight Loss Quest',
      );
    });

    test('trims whitespace', () {
      final title = QuestTitle(
        '   90 Day Weight Loss Quest   ',
      );

      expect(
        title.value,
        '90 Day Weight Loss Quest',
      );
    });

    test('throws when empty', () {
      expect(
        () => QuestTitle(''),
        throwsArgumentError,
      );
    });

    test('throws when whitespace only', () {
      expect(
        () => QuestTitle('   '),
        throwsArgumentError,
      );
    });

    test('throws when longer than 100 characters', () {
      expect(
        () => QuestTitle('a' * 101),
        throwsArgumentError,
      );
    });

    test('allows exactly 100 characters', () {
      expect(
        () => QuestTitle('a' * 100),
        returnsNormally,
      );
    });

    test('equal when values match', () {
      expect(
        QuestTitle('Quest'),
        equals(
          QuestTitle('Quest'),
        ),
      );
    });

    test('not equal when values differ', () {
      expect(
        QuestTitle('Quest A'),
        isNot(
          equals(
            QuestTitle('Quest B'),
          ),
        ),
      );
    });

    test('hashCodes match for equal values', () {
      expect(
        QuestTitle('Quest').hashCode,
        QuestTitle('Quest').hashCode,
      );
    });

    test('toString returns title value', () {
      expect(
        QuestTitle('Quest').toString(),
        'Quest',
      );
    });
  });
}
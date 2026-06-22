import 'package:everyonesheroes/features/life_journey/domain/value_objects/insight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Insight', () {
    test('creates insight', () {
      final insight = Insight(
        statement: 'Consistency matters.',
        confidence: 0.9,
      );

      expect(insight.statement, 'Consistency matters.');

      expect(insight.confidence, 0.9);
    });

    test('requires statement', () {
      expect(
        () => Insight(statement: '', confidence: 0.5),
        throwsArgumentError,
      );
    });

    test('accepts confidence of 0', () {
      final insight = Insight(statement: 'Test', confidence: 0);

      expect(insight.confidence, 0);
    });

    test('accepts confidence of 1', () {
      final insight = Insight(statement: 'Test', confidence: 1);

      expect(insight.confidence, 1);
    });

    test('rejects confidence below 0', () {
      expect(
        () => Insight(statement: 'Test', confidence: -0.1),
        throwsArgumentError,
      );
    });

    test('rejects confidence above 1', () {
      expect(
        () => Insight(statement: 'Test', confidence: 1.1),
        throwsArgumentError,
      );
    });

    test('supports equality', () {
      final left = Insight(statement: 'behavioral', confidence: 0.8);

      final right = Insight(statement: 'behavioral', confidence: 0.8);

      expect(left, equals(right));

      expect(left.hashCode, right.hashCode);
    });

    test('different confidence is not equal', () {
      final left = Insight(statement: 'behavioral', confidence: 0.8);

      final right = Insight(statement: 'behavioral', confidence: 0.9);

      expect(left, isNot(equals(right)));
    });
  });
}

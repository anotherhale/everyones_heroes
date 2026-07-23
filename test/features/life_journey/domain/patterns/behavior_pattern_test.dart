import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/features/life_journey/domain/domain.dart';

void main() {
  late BehavioralEvidence evidence1;
  late BehavioralEvidence evidence2;
  late BehaviorPattern pattern;

  setUp(() {
    evidence1 = BehavioralEvidence(
      type: BehavioralEvidenceType.discipline,
      observedAt: DateTime(2026, 1, 1),
      source: const ReflectionEvidenceSource(
        reflectionId: ReflectionId('reflection-1'),
      ),
      strength: Strength(.80),
    );

    evidence2 = BehavioralEvidence(
      type: BehavioralEvidenceType.discipline,
      observedAt: DateTime(2026, 1, 10),
      source: const ReflectionEvidenceSource(
        reflectionId: ReflectionId('reflection-2'),
      ),
      strength: const Strength(.90),
    );

    pattern = BehaviorPattern(
      type: BehaviorPatternType.consistency,
      strength: const Strength(.85),
      supportingEvidence: [evidence1, evidence2],
      firstObservedAt: evidence1.observedAt,
      lastObservedAt: evidence2.observedAt,
    );
  });

  group('constructor', () {
    test('creates a valid behavior pattern', () {
      expect(pattern.type, BehaviorPatternType.consistency);

      expect(pattern.strength, const Strength(.85));

      expect(pattern.supportingEvidence.length, 2);
    });

    test('throws when fewer than two observations are supplied', () {
      expect(
        () => BehaviorPattern(
          type: BehaviorPatternType.consistency,
          strength: const Strength(.80),
          supportingEvidence: [evidence1],
          firstObservedAt: evidence1.observedAt,
          lastObservedAt: evidence1.observedAt,
        ),
        throwsAssertionError,
      );
    });
  });

  group('derived properties', () {
    test('observationCount', () {
      expect(pattern.observationCount, 2);
    });

    test('observedDuration', () {
      expect(pattern.observedDuration, const Duration(days: 9));
    });

    test('isStrong', () {
      expect(pattern.isStrong, isTrue);
      expect(pattern.isModerate, isFalse);
      expect(pattern.isWeak, isFalse);
    });
  });

  group('immutability', () {
    test('supportingEvidence is unmodifiable', () {
      expect(
        () => pattern.supportingEvidence.add(evidence1),
        throwsUnsupportedError,
      );
    });
  });

  group('equality', () {
    test('identical patterns are equal', () {
      final other = BehaviorPattern(
        type: BehaviorPatternType.consistency,
        strength: const Strength(.85),
        supportingEvidence: [evidence1, evidence2],
        firstObservedAt: evidence1.observedAt,
        lastObservedAt: evidence2.observedAt,
      );

      expect(pattern, other);
      expect(pattern.hashCode, other.hashCode);
    });

    test('different type is not equal', () {
      final other = BehaviorPattern(
        type: BehaviorPatternType.courage,
        strength: const Strength(.85),
        supportingEvidence: [evidence1, evidence2],
        firstObservedAt: evidence1.observedAt,
        lastObservedAt: evidence2.observedAt,
      );

      expect(pattern, isNot(other));
    });
  });

  group('toString', () {
    test('contains useful information', () {
      expect(pattern.toString(), contains('consistency'));

      expect(pattern.toString(), contains('observations: 2'));
    });
  });
}

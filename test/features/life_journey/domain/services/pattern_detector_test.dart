import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/reflection_id.dart';

import 'package:everyonesheroes/features/life_journey/domain/domain.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/services/rule_based/rule_based_pattern_detector.dart';

void main() {
  group('RuleBasedPatternDetector', () {
    late RuleBasedPatternDetector detector;

    setUp(() {
      detector = RuleBasedPatternDetector();
    });

    BehavioralEvidence evidence({
      required BehavioralEvidenceType type,
      required double strength,
    }) {
      return BehavioralEvidence(
        type: type,
        strength: Strength(strength),
        source: ReflectionEvidenceSource(reflectionId: ReflectionId.generate()),
      );
    }

    test('returns empty list when no evidence exists', () {
      final patterns = detector.detect(evidence: const []);

      expect(patterns, isEmpty);
    });

    test('groups evidence by type', () {
      final patterns = detector.detect(
        evidence: [
          evidence(type: BehavioralEvidenceType.discipline, strength: .8),
          evidence(type: BehavioralEvidenceType.discipline, strength: .9),
          evidence(type: BehavioralEvidenceType.discipline, strength: .7),
          evidence(type: BehavioralEvidenceType.courage, strength: .6),
          evidence(type: BehavioralEvidenceType.courage, strength: .8),
          evidence(type: BehavioralEvidenceType.courage, strength: .7),
        ],
      );

      expect(patterns.length, 2);
    });

    test('calculates average strength', () {
      final patterns = detector.detect(
        evidence: [
          evidence(type: BehavioralEvidenceType.discipline, strength: .6),
          evidence(type: BehavioralEvidenceType.discipline, strength: .8),
          evidence(type: BehavioralEvidenceType.discipline, strength: 1.0),
        ],
      );

      expect(patterns.single.strength.value, closeTo(0.8, 1e-9));
    });

    test('requires at least three observations', () {
      final patterns = detector.detect(
        evidence: [
          evidence(type: BehavioralEvidenceType.discipline, strength: .8),
          evidence(type: BehavioralEvidenceType.discipline, strength: .9),
        ],
      );

      expect(patterns, isEmpty);
    });

    test('preserves supporting evidence', () {
      final list = [
        evidence(type: BehavioralEvidenceType.discipline, strength: .8),
        evidence(type: BehavioralEvidenceType.discipline, strength: .9),
        evidence(type: BehavioralEvidenceType.discipline, strength: .7),
      ];

      final pattern = detector.detect(evidence: list).single;

      expect(pattern.supportingEvidence, list);
    });

    test('supporting evidence is immutable', () {
      final pattern = detector
          .detect(
            evidence: [
              evidence(type: BehavioralEvidenceType.discipline, strength: .8),
              evidence(type: BehavioralEvidenceType.discipline, strength: .9),
              evidence(type: BehavioralEvidenceType.discipline, strength: .7),
            ],
          )
          .single;

      expect(
        () => pattern.supportingEvidence.add(
          evidence(type: BehavioralEvidenceType.discipline, strength: .5),
        ),
        throwsUnsupportedError,
      );
    });
  });
}

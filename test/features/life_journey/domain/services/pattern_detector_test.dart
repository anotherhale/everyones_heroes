import 'package:everyonesheroes/features/life_journey/infrastructure/services/rule_based/rule_based_pattern_detector.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/features/life_journey/domain/domain.dart';

import '../../builders/behavioral_evidence_builder.dart';

void main() {
  late RuleBasedPatternDetector detector;

  setUp(() {
    detector = const RuleBasedPatternDetector(
      rules: [ConsistencyPatternRule(), CouragePatternRule()],
    );
  });

  group('detect', () {
    test('returns empty when no evidence is supplied', () {
      final patterns = detector.detect(evidence: const []);

      expect(patterns, isEmpty);
    });

    test('returns empty when no rules match', () {
      final patterns = detector.detect(
        evidence: [
          BehavioralEvidenceBuilder.service().build(),
          BehavioralEvidenceBuilder.service().build(),
          BehavioralEvidenceBuilder.service().build(),
        ],
      );

      expect(patterns, isEmpty);
    });

    test('returns a single matching pattern', () {
      final patterns = detector.detect(
        evidence: [
          BehavioralEvidenceBuilder.discipline().build(),
          BehavioralEvidenceBuilder.discipline().build(),
          BehavioralEvidenceBuilder.discipline().build(),
        ],
      );

      expect(patterns, hasLength(1));

      expect(patterns.single.type, BehaviorPatternType.consistency);
    });

    test('returns patterns from all matching rules', () {
      final patterns = detector.detect(
        evidence: [
          BehavioralEvidenceBuilder.discipline().build(),
          BehavioralEvidenceBuilder.discipline().build(),
          BehavioralEvidenceBuilder.discipline().build(),

          BehavioralEvidenceBuilder.courage().build(),
          BehavioralEvidenceBuilder.courage().build(),
          BehavioralEvidenceBuilder.courage().build(),
        ],
      );

      expect(patterns, hasLength(2));

      expect(
        patterns.map((p) => p.type),
        containsAll([
          BehaviorPatternType.consistency,
          BehaviorPatternType.courage,
        ]),
      );
    });

    test('ignores evidence that does not satisfy any rule', () {
      final patterns = detector.detect(
        evidence: [
          BehavioralEvidenceBuilder.discipline().build(),
          BehavioralEvidenceBuilder.discipline().build(), // below threshold

          BehavioralEvidenceBuilder.courage().build(),
          BehavioralEvidenceBuilder.courage().build(), // below threshold

          BehavioralEvidenceBuilder.service().build(),
          BehavioralEvidenceBuilder.leadership().build(),
        ],
      );

      expect(patterns, isEmpty);
    });

    test('returns only matching patterns when some rules fail', () {
      final patterns = detector.detect(
        evidence: [
          BehavioralEvidenceBuilder.discipline().build(),
          BehavioralEvidenceBuilder.discipline().build(),
          BehavioralEvidenceBuilder.discipline().build(),

          BehavioralEvidenceBuilder.courage().build(),
          BehavioralEvidenceBuilder.courage().build(), // below threshold
        ],
      );

      expect(patterns, hasLength(1));

      expect(patterns.single.type, BehaviorPatternType.consistency);
    });
  });
}

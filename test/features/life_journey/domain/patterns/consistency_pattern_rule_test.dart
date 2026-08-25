import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/features/life_journey/domain/domain.dart';

import '../../builders/behavioral_evidence_builder.dart';

void main() {
  late ConsistencyPatternRule rule;

  setUp(() {
    rule = const ConsistencyPatternRule();
  });

  group('detect', () {
    test('returns null when no discipline evidence exists', () {
      final pattern = rule.detect([
        BehavioralEvidenceBuilder.courage().build(),
        BehavioralEvidenceBuilder.courage().build(),
        BehavioralEvidenceBuilder.service().build(),
      ]);

      expect(pattern, isNull);
    });

    test('returns null when fewer than three observations exist', () {
      final pattern = rule.detect([
        BehavioralEvidenceBuilder.discipline().build(),
        BehavioralEvidenceBuilder.discipline().build(),
      ]);

      expect(pattern, isNull);
    });

    test('detects consistency', () {
      final pattern = rule.detect([
        BehavioralEvidenceBuilder.discipline().withStrength(.8).build(),
        BehavioralEvidenceBuilder.discipline().withStrength(.9).build(),
        BehavioralEvidenceBuilder.discipline().withStrength(.7).build(),
      ]);

      expect(pattern, isNotNull);
      expect(pattern!.type, BehaviorPatternType.consistency);
      expect(pattern.observationCount, 3);
      expect(pattern.strength, const Strength(.8));
    });

    test('ignores unrelated evidence', () {
      final pattern = rule.detect([
        BehavioralEvidenceBuilder.discipline().build(),
        BehavioralEvidenceBuilder.courage().build(),
        BehavioralEvidenceBuilder.discipline().build(),
        BehavioralEvidenceBuilder.service().build(),
        BehavioralEvidenceBuilder.discipline().build(),
      ]);

      expect(pattern, isNotNull);
      expect(pattern!.observationCount, 3);
    });
  });
}

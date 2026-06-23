import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/behavioral_evidence_type.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/behavioral_evidence.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/evidence_source.dart';

void main() {
  group('BehavioralEvidence', () {
    test('creates successfully', () {
      final evidence = BehavioralEvidence(
        evidenceType: BehavioralEvidenceType.discipline,
        source: ReflectionEvidenceSource(
          reflectionId: ReflectionId('reflection-1'),
        ),
        strength: 0.8,
      );

      expect(evidence.evidenceType, BehavioralEvidenceType.discipline);

      expect(evidence.strength, 0.8);

      expect(evidence.source, isA<ReflectionEvidenceSource>());
    });

    test('supports strength of 0.0', () {
      final evidence = BehavioralEvidence(
        evidenceType: BehavioralEvidenceType.discipline,
        source: ReflectionEvidenceSource(
          reflectionId: ReflectionId('reflection-1'),
        ),
        strength: 0.0,
      );

      expect(evidence.strength, 0.0);
    });

    test('supports strength of 1.0', () {
      final evidence = BehavioralEvidence(
        evidenceType: BehavioralEvidenceType.discipline,
        source: ReflectionEvidenceSource(
          reflectionId: ReflectionId('reflection-1'),
        ),
        strength: 1.0,
      );

      expect(evidence.strength, 1.0);
    });
  });
}

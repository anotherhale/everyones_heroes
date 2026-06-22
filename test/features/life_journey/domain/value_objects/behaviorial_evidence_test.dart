import 'package:everyonesheroes/features/life_journey/domain/enums/behavioral_signal_type.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/behavioral_evidence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BehavioralEvidence', () {
    test('creates evidence', () {
      final evidence = BehavioralEvidence(
        signalType: BehavioralSignalType.resilience,
        evidence: 'Completed mission despite difficulty.',
        strength: 0.9,
      );

      expect(evidence.signalType, BehavioralSignalType.resilience);

      expect(evidence.evidence, 'Completed mission despite difficulty.');

      expect(evidence.strength, 0.9);
    });

    test('requires evidence text', () {
      expect(
        () => BehavioralEvidence(
          signalType: BehavioralSignalType.resilience,
          evidence: '',
          strength: 0.5,
        ),
        throwsArgumentError,
      );
    });

    test('accepts strength of 0', () {
      final evidence = BehavioralEvidence(
        signalType: BehavioralSignalType.resilience,
        evidence: 'Test',
        strength: 0,
      );

      expect(evidence.strength, 0);
    });

    test('accepts strength of 1', () {
      final evidence = BehavioralEvidence(
        signalType: BehavioralSignalType.resilience,
        evidence: 'Test',
        strength: 1,
      );

      expect(evidence.strength, 1);
    });

    test('rejects strength below 0', () {
      expect(
        () => BehavioralEvidence(
          signalType: BehavioralSignalType.resilience,
          evidence: 'Test',
          strength: -0.1,
        ),
        throwsArgumentError,
      );
    });

    test('rejects strength above 1', () {
      expect(
        () => BehavioralEvidence(
          signalType: BehavioralSignalType.resilience,
          evidence: 'Test',
          strength: 1.1,
        ),
        throwsArgumentError,
      );
    });

    test('supports equality', () {
      final left = BehavioralEvidence(
        signalType: BehavioralSignalType.resilience,
        evidence: 'Did not quit.',
        strength: 0.9,
      );

      final right = BehavioralEvidence(
        signalType: BehavioralSignalType.resilience,
        evidence: 'Did not quit.',
        strength: 0.9,
      );

      expect(left, equals(right));

      expect(left.hashCode, right.hashCode);
    });
  });
}

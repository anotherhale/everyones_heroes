import 'package:everyonesheroes/features/life_journey/domain/domain.dart';
import 'package:everyonesheroes/core/extensions/double_extensions.dart';

abstract base class BasePatternRule implements PatternRule {
  const BasePatternRule();

  List<BehavioralEvidence> evidenceOfType(
    List<BehavioralEvidence> evidence,
    BehavioralEvidenceType type,
  ) {
    return evidence.where((e) => e.type == type).toList(growable: false);
  }

  Strength averageStrength(List<BehavioralEvidence> evidence) {
    final average =
        evidence.map((e) => e.strength.value).reduce((a, b) => a + b) /
        evidence.length;

    return Strength(average.normalizedStrength());
  }

  DateTime firstObservedAt(List<BehavioralEvidence> evidence) {
    return evidence
        .map((e) => e.observedAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }

  DateTime lastObservedAt(List<BehavioralEvidence> evidence) {
    return evidence
        .map((e) => e.observedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  BehaviorPattern createPattern({
    required BehaviorPatternType type,
    required List<BehavioralEvidence> evidence,
  }) {
    return BehaviorPattern(
      type: type,
      strength: averageStrength(evidence),
      supportingEvidence: evidence,
      firstObservedAt: firstObservedAt(evidence),
      lastObservedAt: lastObservedAt(evidence),
    );
  }
}

import 'package:everyonesheroes/features/life_journey/domain/domain.dart';

final class CouragePatternRule extends BasePatternRule {
  const CouragePatternRule();

  static const minimumEvidenceCount = 3;

  @override
  BehaviorPattern? detect(Iterable<BehavioralEvidence> evidence) {
    final courage = evidenceOfType(evidence, BehavioralEvidenceType.courage);

    if (courage.length < minimumEvidenceCount) {
      return null;
    }

    return createPattern(type: BehaviorPatternType.courage, evidence: courage);
  }
}

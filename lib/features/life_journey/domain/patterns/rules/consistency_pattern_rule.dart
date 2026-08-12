import 'package:everyonesheroes/features/life_journey/domain/domain.dart';

final class ConsistencyPatternRule extends BasePatternRule {
  const ConsistencyPatternRule();

  static const minimumEvidenceCount = 3;

  @override
  BehaviorPattern? detect(List<BehavioralEvidence> evidence) {
    final discipline = evidenceOfType(
      evidence,
      BehavioralEvidenceType.discipline,
    );

    if (discipline.length < minimumEvidenceCount) {
      return null;
    }

    return createPattern(
      type: BehaviorPatternType.consistency,
      evidence: discipline,
    );
  }
}

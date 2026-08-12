import 'package:everyonesheroes/features/life_journey/domain/domain.dart';

final class ResponsibilityPatternRule extends BasePatternRule {
  const ResponsibilityPatternRule();

  static const minimumEvidenceCount = 4;

  @override
  BehaviorPattern? detect(List<BehavioralEvidence> evidence) {
    final responsibility = evidenceOfType(
      evidence,
      BehavioralEvidenceType.responsibility,
    );

    if (responsibility.length < minimumEvidenceCount) {
      return null;
    }

    return createPattern(
      type: BehaviorPatternType.responsibility,
      evidence: responsibility,
    );
  }
}

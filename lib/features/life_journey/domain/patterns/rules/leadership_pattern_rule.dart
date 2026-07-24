import 'package:everyonesheroes/features/life_journey/domain/domain.dart';

final class LeadershipPatternRule extends BasePatternRule {
  const LeadershipPatternRule();

  static const minimumEvidenceCount = 4;

  @override
  BehaviorPattern? detect(Iterable<BehavioralEvidence> evidence) {
    final leadership = evidenceOfType(
      evidence,
      BehavioralEvidenceType.leadership,
    );

    if (leadership.length < minimumEvidenceCount) {
      return null;
    }

    return createPattern(
      type: BehaviorPatternType.leadership,
      evidence: leadership,
    );
  }
}

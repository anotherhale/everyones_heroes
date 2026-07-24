import 'package:everyonesheroes/features/life_journey/domain/domain.dart';

final class RecoveryPatternRule extends BasePatternRule {
  const RecoveryPatternRule();

  @override
  BehaviorPattern? detect(Iterable<BehavioralEvidence> evidence) {
    final sorted = [...evidence]
      ..sort((a, b) => a.observedAt.compareTo(b.observedAt));

    // TODO:
    // Detect:
    // Fear/Avoidance/Failure
    // followed by
    // Courage/Discipline/Leadership

    return null;
  }
}

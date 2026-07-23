import 'package:everyonesheroes/features/life_journey/domain/domain.dart';

final class ServicePatternRule extends BasePatternRule {
  const ServicePatternRule();

  static const minimumEvidenceCount = 3;

  @override
  BehaviorPattern? detect(List<BehavioralEvidence> evidence) {
    final service = evidenceOfType(evidence, BehavioralEvidenceType.service);

    if (service.length < minimumEvidenceCount) {
      return null;
    }

    return createPattern(type: BehaviorPatternType.service, evidence: service);
  }
}


import 'package:everyonesheroes/features/life_journey/domain/enums/behavioral_evidence_type.dart';

final class BehaviorPattern {
  const BehaviorPattern({
    required this.name,
    required this.signalType,
    required this.evidenceCount,
  });

  final String name;
  final BehavioralEvidenceType signalType;
  final int evidenceCount;
}

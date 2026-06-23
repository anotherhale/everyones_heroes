import 'package:everyonesheroes/features/life_journey/domain/enums/behavioral_signal_type.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/evidence_source.dart';

final class BehavioralEvidence {
  BehavioralEvidence({
    required this.evidenceType,
    required this.source,
    required this.strength,
  });

  final BehavioralEvidenceType evidenceType;

  final EvidenceSource source;

  final double strength;
}

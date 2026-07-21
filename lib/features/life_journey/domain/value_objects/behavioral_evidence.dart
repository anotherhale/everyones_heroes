import 'package:meta/meta.dart';

import 'package:everyonesheroes/features/life_journey/domain/enums/behavioral_evidence_type.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/evidence_source.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/strength.dart';

@immutable
final class BehavioralEvidence {
  const BehavioralEvidence({
    required this.type,
    required this.source,
    required this.strength,
  });

  final BehavioralEvidenceType type;

  final EvidenceSource source;

  final Strength strength;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BehavioralEvidence &&
          type == other.type &&
          source == other.source &&
          strength == other.strength;

  @override
  int get hashCode => Object.hash(type, source, strength);
}

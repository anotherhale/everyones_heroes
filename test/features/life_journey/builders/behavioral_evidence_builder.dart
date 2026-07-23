import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/features/life_journey/domain/domain.dart';

final class BehavioralEvidenceBuilder {
  BehavioralEvidenceBuilder({
    BehavioralEvidenceType type = BehavioralEvidenceType.discipline,
    double strength = .8,
    DateTime? observedAt,
    EvidenceSource? source,
  }) : _type = type,
       _strength = strength,
       _observedAt = observedAt ?? DateTime(2026, 1, 1),
       _source =
           source ??
           const ReflectionEvidenceSource(
             reflectionId: ReflectionId('reflection-1'),
           );

  BehavioralEvidenceBuilder.discipline()
      : this(type: BehavioralEvidenceType.discipline);

  BehavioralEvidenceBuilder.courage()
      : this(type: BehavioralEvidenceType.courage);

  BehavioralEvidenceBuilder.leadership()
      : this(type: BehavioralEvidenceType.leadership);

  BehavioralEvidenceBuilder.responsibility()
      : this(type: BehavioralEvidenceType.responsibility);

  BehavioralEvidenceBuilder.service()
      : this(type: BehavioralEvidenceType.service);

  BehavioralEvidenceType _type;
  double _strength;
  DateTime _observedAt;
  EvidenceSource _source;

  BehavioralEvidenceBuilder withType(
    BehavioralEvidenceType value,
  ) {
    _type = value;
    return this;
  }

  BehavioralEvidenceBuilder withStrength(
    double value,
  ) {
    _strength = value;
    return this;
  }

  BehavioralEvidenceBuilder observedAt(
    DateTime value,
  ) {
    _observedAt = value;
    return this;
  }

  BehavioralEvidenceBuilder fromSource(
    EvidenceSource value,
  ) {
    _source = value;
    return this;
  }

  BehavioralEvidence build() {
    return BehavioralEvidence(
      type: _type,
      strength: Strength(_strength),
      observedAt: _observedAt,
      source: _source,
    );
  }
}
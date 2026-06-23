import 'package:everyonesheroes/features/life_journey/domain/value_objects/evidence_source.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/services/behavioral_evidencel_analyzer.dart';

import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';

import 'package:everyonesheroes/features/life_journey/domain/enums/behavioral_evidence_type.dart';

import 'package:everyonesheroes/features/life_journey/domain/value_objects/behavioral_evidence.dart';

final class FakeBehavioralEvidenceAnalyzer
    implements BehavioralEvidenceAnalyzer {
  const FakeBehavioralEvidenceAnalyzer();

  @override
  Future<List<BehavioralEvidence>> analyze(Reflection reflection) async {
    if (reflection.responses.isEmpty) {
      return [];
    }

    return [
      BehavioralEvidence(
        evidenceType: BehavioralEvidenceType.resilience,
        source: ReflectionEvidenceSource(reflectionId: reflection.id),
        strength: 0.85,
      ),
    ];
  }
}

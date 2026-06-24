import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/behavioral_evidence_type.dart';
import 'package:everyonesheroes/features/life_journey/domain/services/behavioral_evidence_analyzer.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/behavioral_evidence.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/evidence_source.dart';

final class FakeBehavioralEvidenceAnalyzer
    implements BehavioralEvidenceAnalyzer {
  const FakeBehavioralEvidenceAnalyzer();

  @override
  Future<List<BehavioralEvidence>> analyze(Reflection reflection) async {
    return [
      BehavioralEvidence(
        evidenceType: BehavioralEvidenceType.selfAwareness,
        source: ReflectionEvidenceSource(reflectionId: reflection.id),
        strength: 0.8,
      ),
    ];
  }
}

import 'package:everyonesheroes/features/life_journey/domain/domain.dart';

final class FakeBehavioralEvidenceAnalyzer
    implements BehavioralEvidenceAnalyzer {
  const FakeBehavioralEvidenceAnalyzer();

  @override
  Future<List<BehavioralEvidence>> analyze(Reflection reflection) async {
    return [
      BehavioralEvidence(
        type: BehavioralEvidenceType.selfAwareness,
        source: ReflectionEvidenceSource(reflectionId: reflection.id),
        strength: Strength(0.8),
      ),
    ];
  }
}

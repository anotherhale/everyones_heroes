import 'package:everyonesheroes/features/life_journey/domain/domain.dart';

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
        type: BehavioralEvidenceType.resilience,
        source: ReflectionEvidenceSource(reflectionId: reflection.id),
        strength: Strength(0.85),
        observedAt: DateTime.now(),
      ),
    ];
  }
}

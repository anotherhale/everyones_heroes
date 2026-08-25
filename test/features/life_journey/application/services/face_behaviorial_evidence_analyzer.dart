import 'package:everyonesheroes/core/ids/analyzer_id.dart';
import 'package:everyonesheroes/features/life_journey/domain/domain.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/reflection_response_type.dart';

final class FakeBehavioralEvidenceAnalyzer
    implements BehavioralEvidenceAnalyzer {
  const FakeBehavioralEvidenceAnalyzer();

  @override
  BehavioralAnalyzerDescriptor get descriptor => BehavioralAnalyzerDescriptor(
    id: AnalyzerId.generate(),
    capabilities: {BehavioralAnalyzerCapability.journal},
  );

  @override
  bool supports(BehavioralEvidenceAnalysisContext context) {
    return context.response.type == ReflectionResponseType.journal;
  }

  @override
  Future<List<BehavioralEvidence>> analyze(
    BehavioralEvidenceAnalysisContext context,
  ) async {
    return [
      BehavioralEvidence(
        type: BehavioralEvidenceType.selfAwareness,
        source: ReflectionEvidenceSource(reflectionId: context.reflectionId),
        strength: Strength(0.8),
        observedAt: DateTime.now(),
      ),
    ];
  }
}

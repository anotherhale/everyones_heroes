import 'package:everyonesheroes/features/life_journey/domain/domain.dart';

final class BehavioralEvidenceAnalysisOrchestrator {
  const BehavioralEvidenceAnalysisOrchestrator({required this.registry});

  final BehavioralEvidenceAnalyzerRegistry registry;

  Future<List<BehavioralEvidence>> analyze(Reflection reflection) async {
    final evidence = <BehavioralEvidence>[];

    for (final response in reflection.responses) {
      final context = BehavioralEvidenceAnalysisContext(
        reflectionId: reflection.id,
        response: response,
      );

      final analyzers = registry.analyzersFor(context);

      for (final analyzer in analyzers) {
        evidence.addAll(await analyzer.analyze(context));
      }
    }

    return List.unmodifiable(evidence);
  }
}

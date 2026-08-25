import 'package:everyonesheroes/features/life_journey/domain/services/behavioral_evidence_analysis_context.dart';
import 'package:everyonesheroes/features/life_journey/domain/services/behavioral_evidence_analyzer_registry.dart';
import 'package:everyonesheroes/features/life_journey/domain/services/behavioral_evidence_analyzer.dart';

final class DefaultBehavioralEvidenceAnalyzerRegistry
    implements BehavioralEvidenceAnalyzerRegistry {
  DefaultBehavioralEvidenceAnalyzerRegistry(
    Iterable<BehavioralEvidenceAnalyzer> analyzers,
  ) : _analyzers = List.unmodifiable(analyzers);

  final List<BehavioralEvidenceAnalyzer> _analyzers;

  @override
  List<BehavioralEvidenceAnalyzer> get availableAnalyzers => _analyzers;

  @override
  List<BehavioralEvidenceAnalyzer> analyzersFor(
    BehavioralEvidenceAnalysisContext context,
  ) => _analyzers
      .where((analyzer) => analyzer.supports(context))
      .toList(growable: false);
}

import 'package:eh_platform/src/life_journey/domain/services/behavioral_evidence_analysis_context.dart';
import 'package:eh_platform/src/life_journey/domain/services/behavioral_evidence_analyzer.dart';

abstract interface class BehavioralEvidenceAnalyzerRegistry {
  List<BehavioralEvidenceAnalyzer> get availableAnalyzers;

  List<BehavioralEvidenceAnalyzer> analyzersFor(
    BehavioralEvidenceAnalysisContext context,
  );
}

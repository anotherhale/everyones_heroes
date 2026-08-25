import 'package:everyonesheroes/features/life_journey/domain/services/behavioral_analyzer_descriptor.dart';
import 'package:everyonesheroes/features/life_journey/domain/services/behavioral_evidence_analysis_context.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/behavioral_evidence.dart';

abstract interface class BehavioralEvidenceAnalyzer {
  BehavioralAnalyzerDescriptor get descriptor;

  bool supports(BehavioralEvidenceAnalysisContext context);

  Future<List<BehavioralEvidence>> analyze(
    BehavioralEvidenceAnalysisContext context,
  );
}

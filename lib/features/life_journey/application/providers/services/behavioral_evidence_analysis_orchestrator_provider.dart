import 'package:everyonesheroes/features/life_journey/application/services/behavioral_evidence_analysis_orchestrator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'behavioral_evidence_analyzer_registry_provider.dart';

final behavioralEvidenceAnalysisOrchestratorProvider =
    Provider<BehavioralEvidenceAnalysisOrchestrator>((ref) {
      return BehavioralEvidenceAnalysisOrchestrator(
        registry: ref.read(behavioralEvidenceAnalyzerRegistryProvider),
      );
    });

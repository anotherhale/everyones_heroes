import 'package:everyonesheroes/features/life_journey/application/services/default_behavioral_evidence_analyzer_registry.dart';
import 'package:everyonesheroes/features/life_journey/domain/services/behavioral_evidence_analyzer.dart';
import 'package:everyonesheroes/features/life_journey/domain/services/behavioral_evidence_analyzer_registry.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/services/behavioral_analysis/emoji_behavioral_evidence_analyzer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final behavioralEvidenceAnalyzerRegistryProvider =
    Provider<BehavioralEvidenceAnalyzerRegistry>((ref) {
      const analyzers = <BehavioralEvidenceAnalyzer>[
        EmojiBehavioralEvidenceAnalyzer(),
      ];

      return DefaultBehavioralEvidenceAnalyzerRegistry(analyzers);
    });

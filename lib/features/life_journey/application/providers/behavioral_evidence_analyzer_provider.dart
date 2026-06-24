import 'package:everyonesheroes/features/life_journey/application/providers/fake/fake_behavioral_evidence_analyzer.dart';
import 'package:everyonesheroes/features/life_journey/domain/services/behavioral_evidence_analyzer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final behavioralEvidenceAnalyzerProvider = Provider<BehavioralEvidenceAnalyzer>(
  (ref) {
    return FakeBehavioralEvidenceAnalyzer();
  },
);

import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';

import 'package:everyonesheroes/features/life_journey/domain/value_objects/behavioral_evidence.dart';

abstract interface class BehavioralEvidenceAnalyzer {
  Future<List<BehavioralEvidence>> analyze(Reflection reflection);
}

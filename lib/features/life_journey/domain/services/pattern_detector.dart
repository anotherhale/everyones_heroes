
import 'package:everyonesheroes/features/life_journey/domain/value_objects/behavior_pattern.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/behavioral_evidence.dart';

abstract interface class PatternDetector {
  Future<List<BehaviorPattern>> detectPatterns(
    List<BehavioralEvidence> evidence,
  );
}

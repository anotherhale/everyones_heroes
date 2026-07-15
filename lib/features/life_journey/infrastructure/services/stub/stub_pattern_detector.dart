import 'package:everyonesheroes/features/life_journey/domain/services/pattern_detector.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/behavioral_evidence.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/behavior_pattern.dart';
final class StubPatternDetector implements PatternDetector {
  @override
  Future<List<BehaviorPattern>> detectPatterns(
    List<BehavioralEvidence> evidence,
  ) async {
    return const [];
  }
}
import 'package:everyonesheroes/features/life_journey/domain/services/pattern_detector.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/behavioral_evidence.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/behavior_pattern.dart';

final class DetectPatternsUseCase {
  const DetectPatternsUseCase({
    required PatternDetector patternDetector,
  }) : _patternDetector = patternDetector;

  final PatternDetector _patternDetector;

  Future<List<BehaviorPattern>> execute(
    List<BehavioralEvidence> evidence,
  ) {
    return _patternDetector.detectPatterns(evidence);
  }
}

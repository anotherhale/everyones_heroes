import 'package:everyonesheroes/features/life_journey/domain/domain.dart';

final class DetectPatternsUseCase {
  const DetectPatternsUseCase({required PatternDetector detector})
    : _detector = detector;

  final PatternDetector _detector;

  List<BehaviorPattern> execute({required List<BehavioralEvidence> evidence}) {
    return _detector.detect(evidence: evidence);
  }
}

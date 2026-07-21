import 'package:everyonesheroes/features/life_journey/domain/services/pattern_detector.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/behavioral_evidence.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/pattern.dart';

final class StubPatternDetector implements PatternDetector {
  @override
  List<Pattern> detect({required List<BehavioralEvidence> evidence}) {
    // TODO: implement detect
    throw UnimplementedError();
  }
}

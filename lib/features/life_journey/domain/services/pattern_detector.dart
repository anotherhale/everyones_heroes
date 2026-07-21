import 'package:everyonesheroes/features/life_journey/domain/domain.dart';

/// Detects recurring behavioral patterns from accumulated Behavioral Evidence.
///
/// Pattern detection is deterministic by default. AI implementations may
/// enhance pattern recognition but must produce equivalent domain concepts.
abstract interface class PatternDetector {
  List<Pattern> detect({required List<BehavioralEvidence> evidence});
}

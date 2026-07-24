import 'package:everyonesheroes/features/life_journey/domain/domain.dart';

abstract interface class PatternRule {
  /// Attempts to detect a behavioral pattern.
  ///
  /// Returns `null` if the pattern is not present.
  BehaviorPattern? detect(Iterable<BehavioralEvidence> evidence);
}

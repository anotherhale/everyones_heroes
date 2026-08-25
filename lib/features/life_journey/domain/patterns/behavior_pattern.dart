import 'package:everyonesheroes/features/life_journey/domain/patterns/behavior_pattern_type.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/strength.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/behavioral_evidence.dart';

final class BehaviorPattern {
  final BehaviorPatternType type;
  final Strength strength;
  final List<BehavioralEvidence> supportingEvidence;
  final DateTime firstObservedAt;
  final DateTime lastObservedAt;

  BehaviorPattern({
    required this.type,
    required this.strength,
    required List<BehavioralEvidence> supportingEvidence,
    required this.firstObservedAt,
    required this.lastObservedAt,
  }) : assert(
         supportingEvidence.length > 1,
         'A behavior pattern requires multiple observations.',
       ),
       supportingEvidence = List.unmodifiable(supportingEvidence);

  int get observationCount => supportingEvidence.length;

  Duration get observedDuration => lastObservedAt.difference(firstObservedAt);

  bool get isStrong => strength.isStrong;

  bool get isModerate => strength.isModerate;

  bool get isWeak => strength.isWeak;

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) {
      return true;
    }

    if (a.length != b.length) {
      return false;
    }

    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }

    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BehaviorPattern &&
          type == other.type &&
          strength == other.strength &&
          _listEquals(supportingEvidence, other.supportingEvidence) &&
          firstObservedAt == other.firstObservedAt &&
          lastObservedAt == other.lastObservedAt;

  @override
  int get hashCode => Object.hash(
    type,
    strength,
    Object.hashAll(supportingEvidence),
    firstObservedAt,
    lastObservedAt,
  );

  @override
  String toString() =>
      'BehaviorPattern('
      'type: $type, '
      'strength: $strength, '
      'observations: $observationCount'
      ')';
}

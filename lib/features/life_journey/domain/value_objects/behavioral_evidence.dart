import 'package:collection/collection.dart';

import 'package:everyonesheroes/features/life_journey/domain/enums/behavioral_signal_type.dart';

final class BehavioralEvidence {
  BehavioralEvidence({
    required this.signalType,
    required this.evidence,
    required this.strength,
  }) {
    if (evidence.trim().isEmpty) {
      throw ArgumentError('Evidence cannot be empty.');
    }

    if (strength < 0 || strength > 1) {
      throw ArgumentError('Strength must be between 0 and 1.');
    }
  }

  final BehavioralSignalType signalType;

  final String evidence;

  /// 0.0 - 1.0
  final double strength;

  static const DeepCollectionEquality _equality = DeepCollectionEquality();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BehavioralEvidence &&
            signalType == other.signalType &&
            _equality.equals(evidence, other.evidence) &&
            strength == other.strength;
  }

  @override
  int get hashCode =>
      Object.hash(signalType, _equality.hash(evidence), strength);

  @override
  String toString() {
    return '$signalType: $evidence';
  }
}

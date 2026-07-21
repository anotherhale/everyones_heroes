import 'package:meta/meta.dart';

import '../domain.dart';

@immutable
final class Pattern {
  final BehavioralEvidenceType type;
  final Strength strength;
  final List<BehavioralEvidence> supportingEvidence;

  Pattern({
    required this.type,
    required this.strength,
    required List<BehavioralEvidence> supportingEvidence,
  }) : supportingEvidence = List.unmodifiable(supportingEvidence);

  bool get isStrong => strength.isStrong;

  bool get isModerate => strength.isModerate;

  bool get isWeak => strength.isWeak;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pattern &&
          type == other.type &&
          strength == other.strength &&
          _listEquals(supportingEvidence, other.supportingEvidence);

  @override
  int get hashCode =>
      Object.hash(type, strength, Object.hashAll(supportingEvidence));

  @override
  String toString() =>
      'BehaviorPattern(type: $type, strength: $strength, evidence: ${supportingEvidence.length})';

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;

    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }

    return true;
  }
}

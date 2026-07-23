import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'package:everyonesheroes/features/life_journey/domain/value_objects/behavioral_evidence.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/strength.dart';
import 'package:everyonesheroes/core/extensions/double_extensions.dart';

@immutable
final class EvidenceStatistics {
  factory EvidenceStatistics(List<BehavioralEvidence> evidence) {
    return EvidenceStatistics._(List.unmodifiable(evidence));
  }

  const EvidenceStatistics._(this.supportingEvidence);

  final List<BehavioralEvidence> supportingEvidence;

  bool get isEmpty => supportingEvidence.isEmpty;

  bool get isNotEmpty => supportingEvidence.isNotEmpty;

  int get observationCount => supportingEvidence.length;

  DateTime get firstObservedAt => _sortedEvidence.first.observedAt;

  DateTime get lastObservedAt => _sortedEvidence.last.observedAt;

  Duration get duration => lastObservedAt.difference(firstObservedAt);

  Strength get averageStrength {
    if (isEmpty) {
      return const Strength(0);
    }

    final average =
        supportingEvidence
            .map((e) => e.strength.value)
            .reduce((a, b) => a + b) /
        observationCount;

    return Strength(average.normalizedStrength());
  }

  double get minimumStrength =>
      supportingEvidence.map((e) => e.strength.value).reduce(math.min);

  double get maximumStrength =>
      supportingEvidence.map((e) => e.strength.value).reduce(math.max);

  double get variance {
    if (observationCount <= 1) {
      return 0;
    }

    final mean = averageStrength.value;

    final sum = supportingEvidence.fold<double>(0, (total, evidence) {
      final difference = evidence.strength.value - mean;
      return total + difference * difference;
    });

    return sum / observationCount;
  }

  double get standardDeviation => math.sqrt(variance);

  /// Linear regression slope.
  ///
  /// > 0 = increasing
  /// < 0 = decreasing
  /// = 0 = stable
  double get slope {
    if (observationCount <= 1) {
      return 0;
    }

    final values = _sortedEvidence
        .map((e) => e.strength.value)
        .toList(growable: false);

    final n = values.length;

    final meanX = (n - 1) / 2;
    final meanY = values.reduce((a, b) => a + b) / n;

    double numerator = 0;
    double denominator = 0;

    for (var i = 0; i < n; i++) {
      final dx = i - meanX;
      final dy = values[i] - meanY;

      numerator += dx * dy;
      denominator += dx * dx;
    }

    return denominator == 0 ? 0 : numerator / denominator;
  }

  bool get isIncreasing => slope > 0.02;

  bool get isDecreasing => slope < -0.02;

  bool get isStable => slope.abs() <= 0.02;

  bool get isConsistent => standardDeviation < 0.10;

  bool get isVolatile => standardDeviation >= 0.25;

  bool get hasMomentum => isIncreasing && observationCount >= 5 && isConsistent;

  bool get hasRegression => isDecreasing && observationCount >= 5;

  bool get hasPlateau => isStable && observationCount >= 5 && isConsistent;

  List<BehavioralEvidence> get _sortedEvidence {
    final sorted = [...supportingEvidence]
      ..sort((a, b) => a.observedAt.compareTo(b.observedAt));

    return sorted;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvidenceStatistics &&
          _listEquals(supportingEvidence, other.supportingEvidence);

  @override
  int get hashCode => Object.hashAll(supportingEvidence);

  static bool _listEquals<T>(List<T> a, List<T> b) {
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
}

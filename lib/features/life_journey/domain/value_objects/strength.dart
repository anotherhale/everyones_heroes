import 'package:meta/meta.dart';

@immutable
final class Strength {
  final double value;

  const Strength(this.value)
    : assert(
        value >= 0.0 && value <= 1.0,
        'PatternStrength must be between 0.0 and 1.0.',
      );

  bool get isWeak => value < 0.30;

  bool get isModerate => value >= 0.30 && value < 0.70;

  bool get isStrong => value >= 0.70;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Strength && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toStringAsFixed(2);
}

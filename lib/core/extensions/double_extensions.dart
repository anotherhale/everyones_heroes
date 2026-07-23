extension DoubleStrengthExtensions on double {
  /// Rounds to two decimal places.
  double normalizedStrength() =>
      (this * 100).roundToDouble() / 100;
}
import 'package:collection/collection.dart';

final class Insight {
  Insight({required this.statement, required this.confidence}) {
    if (statement.trim().isEmpty) {
      throw ArgumentError('Insight statement cannot be empty.');
    }

    if (confidence < 0 || confidence > 1) {
      throw ArgumentError('Confidence must be between 0 and 1.');
    }
  }

  final String statement;

  final double confidence;

  static const DeepCollectionEquality _equality = DeepCollectionEquality();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Insight &&
            _equality.equals(statement, other.statement) &&
            confidence == other.confidence;
  }

  @override
  int get hashCode => Object.hash(_equality.hash(statement), confidence);
}

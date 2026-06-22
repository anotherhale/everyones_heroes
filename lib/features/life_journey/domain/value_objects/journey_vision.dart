import 'package:collection/collection.dart';

final class JourneyVision {
  JourneyVision(String value) : value = value.trim() {
    if (this.value.isEmpty) {
      throw ArgumentError('Journey vision cannot be empty.');
    }

    if (this.value.length < 3) {
      throw ArgumentError('Journey vision must be at least 3 characters.');
    }

    if (this.value.length > 500) {
      throw ArgumentError('Journey vision cannot exceed 500 characters.');
    }
  }

  final String value;

  static const DeepCollectionEquality _equality = DeepCollectionEquality();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is JourneyVision && _equality.equals(value, other.value);
  }

  @override
  int get hashCode => _equality.hash(value);

  @override
  String toString() => value;
}

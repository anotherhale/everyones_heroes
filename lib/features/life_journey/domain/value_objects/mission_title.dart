import 'package:collection/collection.dart';

final class MissionTitle {
  MissionTitle(String value)
      : value = value.trim() {
    if (this.value.isEmpty) {
      throw ArgumentError(
        'Mission title cannot be empty.',
      );
    }

    if (this.value.length > 100) {
      throw ArgumentError(
        'Mission title cannot exceed 100 characters.',
      );
    }
  }

  final String value;

  static const DeepCollectionEquality _equality =
      DeepCollectionEquality();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MissionTitle &&
            _equality.equals(value, other.value);
  }

  @override
  int get hashCode => _equality.hash(value);

  @override
  String toString() => value;
}
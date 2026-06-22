import 'package:collection/collection.dart';

final class QuestTitle {
  QuestTitle(String value)
      : value = value.trim() {
    if (this.value.isEmpty) {
      throw ArgumentError(
        'Quest title cannot be empty.',
      );
    }

    if (this.value.length > 100) {
      throw ArgumentError(
        'Quest title cannot exceed 100 characters.',
      );
    }
  }

  final String value;

  static const DeepCollectionEquality _equality =
      DeepCollectionEquality();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is QuestTitle &&
            _equality.equals(value, other.value);
  }

  @override
  int get hashCode => _equality.hash(value);

  @override
  String toString() => value;
}
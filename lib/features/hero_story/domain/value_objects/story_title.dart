import 'package:everyonesheroes/core/shared_kernel/value_object.dart';

final class StoryTitle extends ValueObject {
  StoryTitle(String value) : value = value.trim() {
    if (this.value.isEmpty) {
      throw ArgumentError('Story title cannot be empty.');
    }

    if (this.value.length > 300) {
      throw ArgumentError('Story title cannot exceed 300 characters.');
    }
  }

  final String value;

  @override
  List<Object?> get equalityProps => [value];

  @override
  String toString() => value;
}

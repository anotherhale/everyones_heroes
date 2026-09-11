import 'package:everyonesheroes/core/shared_kernel/value_object.dart';

/// Canonical narrative text of a Story.
///
/// Distinct from media representations such as audio or transcripts.
final class StoryNarrative extends ValueObject {
  StoryNarrative(String value) : value = value.trim() {
    if (this.value.isEmpty) {
      throw ArgumentError('Story narrative cannot be empty.');
    }

    if (this.value.length > 100000) {
      throw ArgumentError('Story narrative cannot exceed 100000 characters.');
    }
  }

  final String value;

  @override
  List<Object?> get equalityProps => [value];

  @override
  String toString() => value;
}

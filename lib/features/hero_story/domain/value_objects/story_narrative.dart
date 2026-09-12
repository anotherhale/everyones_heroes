import 'package:everyonesheroes/core/shared_kernel/value_object.dart';

/// Canonical narrative text of a Story.
///
/// Distinct from media representations such as audio or transcripts.
/// Capture drafts may use [StoryNarrative.provisional] until authored.
final class StoryNarrative extends ValueObject {
  static const String provisionalText =
      '[Provisional capture narrative — awaiting Hero authorship]';

  StoryNarrative(String value, {this.isProvisional = false})
      : value = value.trim() {
    if (this.value.isEmpty) {
      throw ArgumentError('Story narrative cannot be empty.');
    }

    if (this.value.length > 100000) {
      throw ArgumentError('Story narrative cannot exceed 100000 characters.');
    }
  }

  /// Explicit provisional placeholder for capture-first drafts (HS-ADR-017).
  ///
  /// This is not AI-authored content and does not replace the canonical Story.
  factory StoryNarrative.provisional() {
    return StoryNarrative(provisionalText, isProvisional: true);
  }

  final String value;
  final bool isProvisional;

  @override
  List<Object?> get equalityProps => [value, isProvisional];

  @override
  String toString() => value;
}

import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/source_span_reference.dart';

/// One grounded claim derived from a transcript (HS.12.3).
///
/// Every element must carry a [sourceSpan] into the transcript so the Hero
/// can trace the claim back to words they actually spoke.
final class GroundedStoryElement extends ValueObject {
  GroundedStoryElement({
    required this.text,
    required this.sourceSpan,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Grounded story element text cannot be empty.');
    }
    if (trimmed.length > maxTextLength) {
      throw ArgumentError(
        'Grounded story element text exceeds $maxTextLength characters.',
      );
    }
    final start = sourceSpan.startOffset;
    final end = sourceSpan.endOffset;
    if (start == null || end == null) {
      throw ArgumentError(
        'Grounded story element requires character startOffset and endOffset.',
      );
    }
    if (start < 0 || end < start) {
      throw ArgumentError(
        'Grounded story element source span offsets are invalid.',
      );
    }
  }

  static const int maxTextLength = 500;

  final String text;
  final SourceSpanReference sourceSpan;

  @override
  List<Object?> get equalityProps => [text, sourceSpan];
}

/// A short theme label grounded in the transcript (HS.12.3).
final class GroundedStoryTheme extends ValueObject {
  GroundedStoryTheme({
    required this.label,
    required this.sourceSpan,
  }) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Grounded story theme label cannot be empty.');
    }
    if (trimmed.length > maxLabelLength) {
      throw ArgumentError(
        'Grounded story theme label exceeds $maxLabelLength characters.',
      );
    }
    final start = sourceSpan.startOffset;
    final end = sourceSpan.endOffset;
    if (start == null || end == null) {
      throw ArgumentError(
        'Grounded story theme requires character startOffset and endOffset.',
      );
    }
    if (start < 0 || end < start) {
      throw ArgumentError(
        'Grounded story theme source span offsets are invalid.',
      );
    }
  }

  static const int maxLabelLength = 80;

  final String label;
  final SourceSpanReference sourceSpan;

  @override
  List<Object?> get equalityProps => [label, sourceSpan];
}

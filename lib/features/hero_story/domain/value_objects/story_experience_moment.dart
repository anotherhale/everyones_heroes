import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/source_span_reference.dart';

/// A story-derived key moment grounded in the transcript (HS.12.4).
///
/// Every claim must carry a [sourceSpan] into the transcript (HS-ADR-072 /
/// HS-ADR-073). [id] enables typed sequence references.
final class StoryExperienceMoment extends ValueObject {
  StoryExperienceMoment({
    required String id,
    required String description,
    required this.sourceSpan,
  })  : id = id.trim(),
        description = description.trim() {
    if (this.id.isEmpty) {
      throw ArgumentError('StoryExperienceMoment.id cannot be empty.');
    }
    if (this.description.isEmpty) {
      throw ArgumentError('StoryExperienceMoment.description cannot be empty.');
    }
    if (this.description.length > maxDescriptionLength) {
      throw ArgumentError(
        'StoryExperienceMoment.description exceeds '
        '$maxDescriptionLength characters.',
      );
    }
    final start = sourceSpan.startOffset;
    final end = sourceSpan.endOffset;
    if (start == null || end == null) {
      throw ArgumentError(
        'StoryExperienceMoment requires character startOffset and endOffset.',
      );
    }
    if (start < 0 || end < start) {
      throw ArgumentError(
        'StoryExperienceMoment source span offsets are invalid.',
      );
    }
  }

  static const int maxDescriptionLength = 500;

  final String id;
  final String description;
  final SourceSpanReference sourceSpan;

  @override
  List<Object?> get equalityProps => [id, description, sourceSpan];
}

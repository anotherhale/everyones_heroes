import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/value_object.dart';

/// Minimal optional reference into source representation content.
///
/// May use character offsets and/or opaque timestamps. Never fabricate spans.
final class SourceSpanReference extends ValueObject {
  const SourceSpanReference({
    required this.representationId,
    this.startOffset,
    this.endOffset,
    this.startTimestampMs,
    this.endTimestampMs,
    this.opaquePosition,
  });

  final StoryRepresentationId representationId;
  final int? startOffset;
  final int? endOffset;
  final int? startTimestampMs;
  final int? endTimestampMs;
  final String? opaquePosition;

  @override
  List<Object?> get equalityProps => [
    representationId,
    startOffset,
    endOffset,
    startTimestampMs,
    endTimestampMs,
    opaquePosition,
  ];
}

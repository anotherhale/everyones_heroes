import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/shared_kernel/value_object.dart';

/// A derived interpretive claim grounded in Hero response provenance (SB.8).
///
/// Never copies Hero-authored response text. Optional [derivedInterpretation]
/// is analysis only — never canonical story prose.
final class UnderstoodClaim extends ValueObject {
  UnderstoodClaim({
    required Iterable<StoryBuilderResponseId> sourceResponseIds,
    this.derivedInterpretation,
  }) : sourceResponseIds = List.unmodifiable(sourceResponseIds.toList()) {
    if (this.sourceResponseIds.isEmpty) {
      throw ArgumentError(
        'UnderstoodClaim requires at least one sourceResponseId.',
      );
    }
    final note = derivedInterpretation?.trim();
    if (note != null && note.isEmpty) {
      throw ArgumentError(
        'derivedInterpretation cannot be blank when provided.',
      );
    }
    if (note != null && note.length > maxDerivedInterpretationLength) {
      throw ArgumentError(
        'derivedInterpretation exceeds $maxDerivedInterpretationLength chars.',
      );
    }
  }

  static const int maxDerivedInterpretationLength = 500;

  final List<StoryBuilderResponseId> sourceResponseIds;

  /// Optional derived analysis text. Null for deterministic understanding.
  final String? derivedInterpretation;

  @override
  List<Object?> get equalityProps => [
    derivedInterpretation,
    ...sourceResponseIds,
  ];
}

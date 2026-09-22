import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_narrative_role.dart';

/// What the Hero communicated for one SB.3 narrative role (SB.8).
///
/// Structural placement remains [DeterministicStoryStructure]; this captures
/// interpretive presence of Hero material for the role.
final class UnderstoodNarrativeElement extends ValueObject {
  UnderstoodNarrativeElement({
    required this.narrativeRole,
    required Iterable<StoryBuilderResponseId> sourceResponseIds,
    this.derivedNote,
  }) : sourceResponseIds = List.unmodifiable(sourceResponseIds.toList()) {
    if (this.sourceResponseIds.isEmpty) {
      throw ArgumentError(
        'UnderstoodNarrativeElement requires sourceResponseIds.',
      );
    }
    final note = derivedNote?.trim();
    if (note != null && note.isEmpty) {
      throw ArgumentError('derivedNote cannot be blank when provided.');
    }
    if (note != null && note.length > maxDerivedNoteLength) {
      throw ArgumentError(
        'derivedNote exceeds $maxDerivedNoteLength chars.',
      );
    }
  }

  static const int maxDerivedNoteLength = 500;

  final StoryBuilderNarrativeRole narrativeRole;
  final List<StoryBuilderResponseId> sourceResponseIds;

  /// Optional derived analysis. Null for deterministic understanding.
  final String? derivedNote;

  @override
  List<Object?> get equalityProps => [
    narrativeRole,
    derivedNote,
    ...sourceResponseIds,
  ];
}

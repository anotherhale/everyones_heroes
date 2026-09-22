import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_narrative_role.dart';

/// A significant event derived from Hero-authored material (SB.8).
///
/// [label] is a short derived descriptor — not polished story prose and never
/// a substitute for canonical Hero responses.
final class UnderstoodSignificantEvent extends ValueObject {
  UnderstoodSignificantEvent({
    required this.label,
    required Iterable<StoryBuilderResponseId> sourceResponseIds,
    this.narrativeRole,
  }) : sourceResponseIds = List.unmodifiable(sourceResponseIds.toList()) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Significant event label cannot be empty.');
    }
    if (trimmed.length > maxLabelLength) {
      throw ArgumentError(
        'Significant event label exceeds $maxLabelLength chars.',
      );
    }
    if (this.sourceResponseIds.isEmpty) {
      throw ArgumentError(
        'Significant events require at least one sourceResponseId.',
      );
    }
  }

  static const int maxLabelLength = 200;

  final String label;
  final List<StoryBuilderResponseId> sourceResponseIds;
  final StoryBuilderNarrativeRole? narrativeRole;

  @override
  List<Object?> get equalityProps => [
    label,
    narrativeRole,
    ...sourceResponseIds,
  ];
}

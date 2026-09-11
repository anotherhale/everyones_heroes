import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_transformation_type.dart';

/// One transformation step in a Story artifact lineage.
final class ProvenanceStep extends ValueObject {
  ProvenanceStep({
    required this.transformationType,
    required this.producedRepresentationId,
    required this.occurredAt,
    this.sourceRepresentationId,
    this.isAiAssisted = false,
    String? note,
  }) : note = note?.trim().isEmpty == true ? null : note?.trim();

  final StoryTransformationType transformationType;
  final StoryRepresentationId producedRepresentationId;
  final StoryRepresentationId? sourceRepresentationId;
  final DateTime occurredAt;
  final bool isAiAssisted;
  final String? note;

  @override
  List<Object?> get equalityProps => [
    transformationType,
    producedRepresentationId,
    sourceRepresentationId,
    occurredAt,
    isAiAssisted,
    note,
  ];
}

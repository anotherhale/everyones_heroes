import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/provenance_step.dart';

/// Preserved lineage of Story representations and transformations.
final class StoryProvenance extends ValueObject {
  StoryProvenance({
    String? originalSourceDescription,
    Iterable<ProvenanceStep>? steps,
  }) : originalSourceDescription =
           originalSourceDescription?.trim().isEmpty == true
           ? null
           : originalSourceDescription?.trim(),
       steps = List.unmodifiable(steps ?? const <ProvenanceStep>[]);

  static final StoryProvenance empty = StoryProvenance();

  final String? originalSourceDescription;
  final List<ProvenanceStep> steps;

  StoryProvenance append(ProvenanceStep step) {
    return StoryProvenance(
      originalSourceDescription: originalSourceDescription,
      steps: [...steps, step],
    );
  }

  StoryProvenance withOriginalSource(String description) {
    return StoryProvenance(
      originalSourceDescription: description,
      steps: steps,
    );
  }

  @override
  List<Object?> get equalityProps => [originalSourceDescription, ...steps];
}

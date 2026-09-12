import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/analysis_support_level.dart';

/// Analysis-lineage for a StoryUnderstanding run (HS-ADR-026).
///
/// Distinct from Story representation provenance.
final class UnderstandingProvenance extends ValueObject {
  UnderstandingProvenance({
    required Iterable<StoryRepresentationId> sourceRepresentationIds,
    required this.analyzedAt,
    required this.providerLabel,
    required this.processingVersion,
    this.modelLabel,
    this.promptOrTemplateVersion,
    this.supportLevel,
    this.opaqueProviderConfidence,
    this.notes,
  }) : sourceRepresentationIds = List.unmodifiable(
         sourceRepresentationIds.toList(),
       ) {
    if (this.sourceRepresentationIds.isEmpty) {
      throw ArgumentError(
        'Understanding provenance requires at least one source representation.',
      );
    }
    if (providerLabel.trim().isEmpty) {
      throw ArgumentError('Provider label cannot be empty.');
    }
    if (processingVersion.trim().isEmpty) {
      throw ArgumentError('Processing version cannot be empty.');
    }
  }

  final List<StoryRepresentationId> sourceRepresentationIds;
  final DateTime analyzedAt;
  final String providerLabel;
  final String? modelLabel;
  final String? promptOrTemplateVersion;
  final String processingVersion;
  final AnalysisSupportLevel? supportLevel;

  /// Opaque provider-specific confidence for display/audit only — not domain truth.
  final Object? opaqueProviderConfidence;
  final String? notes;

  @override
  List<Object?> get equalityProps => [
    ...sourceRepresentationIds,
    analyzedAt,
    providerLabel,
    modelLabel,
    promptOrTemplateVersion,
    processingVersion,
    supportLevel,
    opaqueProviderConfidence,
    notes,
  ];
}

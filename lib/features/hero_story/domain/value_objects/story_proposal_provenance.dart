import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_understanding_kind.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_derivation_kind.dart';

/// Provenance linking a [StoryProposal] back to Hero-authored Builder material.
///
/// Answers: "Where did this proposal come from?" → [sessionId] (and derivation
/// metadata). Does not duplicate the session; does not invent a second
/// provenance system beyond session linkage + derivation kind.
final class StoryProposalProvenance extends ValueObject {
  StoryProposalProvenance({
    required this.sessionId,
    required this.derivationKind,
    required this.processingVersion,
    this.understandingKind,
    this.understandingProcessingVersion,
  }) {
    if (processingVersion.trim().isEmpty) {
      throw ArgumentError('processingVersion cannot be empty.');
    }
    final uv = understandingProcessingVersion?.trim();
    if (uv != null && uv.isEmpty) {
      throw ArgumentError(
        'understandingProcessingVersion cannot be blank when provided.',
      );
    }
  }

  /// Canonical Story Builder session from which this proposal was derived.
  final StoryBuilderSessionId sessionId;

  final StoryProposalDerivationKind derivationKind;
  final String processingVersion;

  /// Kind of Story Builder Understanding consumed during build, if any.
  final StoryBuilderUnderstandingKind? understandingKind;

  /// Processing version of that Understanding snapshot, if any.
  final String? understandingProcessingVersion;

  @override
  List<Object?> get equalityProps => [
    sessionId,
    derivationKind,
    processingVersion,
    understandingKind,
    understandingProcessingVersion,
  ];
}

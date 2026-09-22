import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_id.dart';
import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_derivation_kind.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/provenance_step.dart';

/// Preserved lineage of Story representations and transformations.
///
/// SB.13 extends provenance with optional materialization linkage so a
/// canonical [Story] can answer: "Where did this Story come from?"
///
/// Content-origin distinctions (heroAuthored vs derived) remain on the
/// accepted [StoryProposal] sections — approval does not rewrite origin.
final class StoryProvenance extends ValueObject {
  StoryProvenance({
    String? originalSourceDescription,
    Iterable<ProvenanceStep>? steps,
    this.materializedFromProposalId,
    this.sourceSessionId,
    this.proposalDerivationKind,
    this.proposalContainedDerivedContent = false,
  }) : originalSourceDescription =
           originalSourceDescription?.trim().isEmpty == true
           ? null
           : originalSourceDescription?.trim(),
       steps = List.unmodifiable(steps ?? const <ProvenanceStep>[]) {
    if (materializedFromProposalId != null && sourceSessionId == null) {
      throw ArgumentError(
        'sourceSessionId is required when materializedFromProposalId is set.',
      );
    }
  }

  static final StoryProvenance empty = StoryProvenance();

  final String? originalSourceDescription;
  final List<ProvenanceStep> steps;

  /// Accepted StoryProposal from which this Story was materialized (SB.13).
  final StoryProposalId? materializedFromProposalId;

  /// Story Builder session that produced the approved proposal (SB.13).
  final StoryBuilderSessionId? sourceSessionId;

  /// Proposal derivation kind at materialization time (deterministic / AI).
  final StoryProposalDerivationKind? proposalDerivationKind;

  /// True when any proposal section had [derived] content origin at
  /// materialization. Does not claim the Hero authored that wording.
  final bool proposalContainedDerivedContent;

  bool get wasMaterializedFromProposal => materializedFromProposalId != null;

  StoryProvenance append(ProvenanceStep step) {
    return StoryProvenance(
      originalSourceDescription: originalSourceDescription,
      steps: [...steps, step],
      materializedFromProposalId: materializedFromProposalId,
      sourceSessionId: sourceSessionId,
      proposalDerivationKind: proposalDerivationKind,
      proposalContainedDerivedContent: proposalContainedDerivedContent,
    );
  }

  StoryProvenance withOriginalSource(String description) {
    return StoryProvenance(
      originalSourceDescription: description,
      steps: steps,
      materializedFromProposalId: materializedFromProposalId,
      sourceSessionId: sourceSessionId,
      proposalDerivationKind: proposalDerivationKind,
      proposalContainedDerivedContent: proposalContainedDerivedContent,
    );
  }

  @override
  List<Object?> get equalityProps => [
    originalSourceDescription,
    ...steps,
    materializedFromProposalId,
    sourceSessionId,
    proposalDerivationKind,
    proposalContainedDerivedContent,
  ];
}

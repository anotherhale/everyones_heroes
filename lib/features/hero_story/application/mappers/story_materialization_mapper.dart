import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/create_story_request.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_content_origin.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_narrative.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_provenance.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_title.dart';

/// Maps an accepted [StoryProposal] into [CreateStoryRequest] (SB.13).
///
/// Lives in the application layer so the canonical Story aggregate does not
/// depend on Story Builder presentation or AI infrastructure.
final class StoryMaterializationMapper {
  const StoryMaterializationMapper();

  /// Deterministic Story identity for a proposal — supports upsert idempotency.
  static StoryId storyIdForProposal(StoryProposalId proposalId) {
    return StoryId('materialized-from-proposal-${proposalId.value}');
  }

  CreateStoryRequest toCreateStoryRequest({
    required StoryProposal proposal,
    required HeroId heroId,
    required LanguageCode originalLanguage,
    StoryId? storyId,
    DateTime? createdAt,
  }) {
    if (!proposal.isAccepted) {
      throw StateError(
        'Only accepted StoryProposals can be materialized '
        '(lifecycle=${proposal.lifecycle.name}).',
      );
    }

    final narrativeText = proposal.narrative?.trim();
    if (narrativeText == null || narrativeText.isEmpty) {
      throw ArgumentError(
        'Cannot materialize a StoryProposal without narrative content.',
      );
    }

    final containedDerived = proposal.sections.any(
      (section) =>
          section.contentOrigin == StoryProposalContentOrigin.derived,
    );

    final provenance = StoryProvenance(
      originalSourceDescription:
          'Materialized from accepted StoryProposal ${proposal.id.value} '
          '(StoryBuilderSession ${proposal.sessionId.value}; '
          'Hero approved; derivation=${proposal.provenance.derivationKind.name})',
      materializedFromProposalId: proposal.id,
      sourceSessionId: proposal.sessionId,
      proposalDerivationKind: proposal.provenance.derivationKind,
      proposalContainedDerivedContent: containedDerived,
    );

    return CreateStoryRequest(
      storyId: storyId ?? storyIdForProposal(proposal.id),
      heroId: heroId,
      title: proposal.title ?? StoryTitle('Untitled Story'),
      narrative: StoryNarrative(narrativeText),
      originalLanguage: originalLanguage,
      visibility: StoryVisibility.draft,
      provenance: provenance,
    );
  }
}

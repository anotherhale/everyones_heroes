import 'package:everyonesheroes/core/ids/story_proposal_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_section_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_content_origin.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_derivation_kind.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/deterministic_story_structure.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_understanding.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal_provenance.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal_section.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_response.dart';

/// Builds a deterministic [StoryProposal] from Builder material (SB.9).
///
/// Offline, AI-agnostic, no Story creation, no session mutation.
/// Section content prefers Hero response text; skipped/empty stay empty.
final class DeterministicStoryProposalBuilder {
  const DeterministicStoryProposalBuilder();

  StoryProposal build({
    required StoryBuilderSession session,
    required DeterministicStoryStructure structure,
    required StoryBuilderUnderstanding understanding,
    StoryProposalId? proposalId,
    DateTime? createdAt,
  }) {
    if (structure.sessionId != session.id) {
      throw ArgumentError(
        'Structure sessionId must match the Story Builder session.',
      );
    }
    if (understanding.sessionId != session.id) {
      throw ArgumentError(
        'Understanding sessionId must match the Story Builder session.',
      );
    }

    final at = createdAt ?? DateTime.now();
    final id = proposalId ?? StoryProposalId.generate();
    final responseById = <Object, StoryBuilderResponse>{
      for (final response in session.responses) response.id: response,
    };

    final sections = <StoryProposalSection>[];
    final narrativeParts = <String>[];

    for (final structureSection in structure.sections) {
      final sourceIds = structureSection.sourceResponseIds;
      final wasSkipped = structureSection.wasSkipped;

      String? content;
      if (structureSection.hasSourceMaterial) {
        final texts = <String>[];
        for (final responseId in sourceIds) {
          final response = responseById[responseId];
          if (response == null) {
            throw StateError(
              'Structure references unknown response ${responseId.value}.',
            );
          }
          if (response.skipped) {
            continue;
          }
          final text = response.text;
          if (text != null) {
            texts.add(text);
          }
        }
        if (texts.isNotEmpty) {
          content = texts.join('\n\n');
          narrativeParts.add(content);
        }
      }

      sections.add(
        StoryProposalSection(
          id: StoryProposalSectionId.generate(),
          narrativeRole: structureSection.narrativeRole,
          order: structureSection.order,
          contentOrigin: StoryProposalContentOrigin.heroAuthored,
          content: content,
          sourceResponseIds: sourceIds,
          wasSkipped: wasSkipped,
        ),
      );
    }

    // No Story Builder title field exists — do not invent titles from AI or
    // polished prose. Explicit absence (null) until Hero review provides one.
    // Understanding may contribute derivedSummary metadata only — never Hero text.
    final derivedSummary = understanding.derivedSummary;

    return StoryProposal(
      id: id,
      sessionId: session.id,
      title: null,
      narrative: narrativeParts.isEmpty ? null : narrativeParts.join('\n\n'),
      sections: sections,
      intent: session.intent,
      provenance: StoryProposalProvenance(
        sessionId: session.id,
        derivationKind: StoryProposalDerivationKind.deterministic,
        processingVersion: StoryProposal.deterministicProcessingVersion,
        understandingKind: understanding.kind,
        understandingProcessingVersion: understanding.processingVersion,
      ),
      lifecycle: StoryProposalLifecycleStatus.readyForReview,
      createdAt: at,
      updatedAt: at,
      derivedSummary: derivedSummary,
    );
  }
}

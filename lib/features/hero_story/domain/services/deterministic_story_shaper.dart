import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_narrative_role.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_content_origin.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_derivation_kind.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_shaper_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal_provenance.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal_section.dart';

/// Offline deterministic Story Proposal shaper (SB.10).
///
/// May reorder, omit empties from presentation, and drop exact duplicates from
/// the assembled narrative. Never invents facts or rewrites Hero-authored text.
///
/// Does not access the network, AI providers, session repositories, or Story
/// materialization. Treats [proposal] as immutable input.
final class DeterministicStoryShaper implements StoryShaperPort {
  const DeterministicStoryShaper();

  /// Canonical SB.3/SB.4 narrative role order (enum declaration order).
  static const List<StoryBuilderNarrativeRole> canonicalRoleOrder =
      StoryBuilderNarrativeRole.values;

  @override
  Future<StoryProposal> shape(StoryProposal proposal) async {
    return shapeSync(proposal);
  }

  /// Synchronous shaping for tests and offline callers.
  StoryProposal shapeSync(
    StoryProposal proposal, {
    DateTime? shapedAt,
  }) {
    final at = shapedAt ?? DateTime.now();

    // Reorder by canonical role; preserve every section (incl. skipped/empty).
    final ordered = _orderedSections(proposal.sections);

    // Rebuild presentation inventory: same section identities/content, new order.
    final shapedSections = <StoryProposalSection>[];
    for (var i = 0; i < ordered.length; i++) {
      final source = ordered[i];
      shapedSections.add(
        StoryProposalSection(
          id: source.id,
          narrativeRole: source.narrativeRole,
          order: i,
          contentOrigin: source.contentOrigin,
          content: source.content,
          sourceResponseIds: source.sourceResponseIds,
          wasSkipped: source.wasSkipped,
          // Deterministic reorder preserves Hero review/edit metadata.
          heroEdited: source.heroEdited,
          heroEditedAt: source.heroEditedAt,
          contentBeforeHeroEdit: source.contentBeforeHeroEdit,
        ),
      );
    }

    final narrative = _assembleNarrative(shapedSections);

    final lifecycle = _lifecycleForShaped(proposal.lifecycle);
    final review = (proposal.lifecycle == StoryProposalLifecycleStatus.accepted ||
            proposal.lifecycle == StoryProposalLifecycleStatus.rejected)
        ? proposal.review.copyWith(editedAfterDecision: true)
        : proposal.review;

    return StoryProposal(
      id: proposal.id,
      sessionId: proposal.sessionId,
      title: proposal.title,
      narrative: narrative,
      sections: shapedSections,
      intent: proposal.intent,
      provenance: StoryProposalProvenance(
        sessionId: proposal.provenance.sessionId,
        derivationKind: StoryProposalDerivationKind.deterministic,
        processingVersion: StoryProposal.shapedProcessingVersion,
        understandingKind: proposal.provenance.understandingKind,
        understandingProcessingVersion:
            proposal.provenance.understandingProcessingVersion,
      ),
      lifecycle: lifecycle,
      createdAt: proposal.createdAt,
      updatedAt: at,
      derivedSummary: proposal.derivedSummary,
      // Shaping never approves; may invalidate prior accept/reject.
      review: review,
    );
  }

  /// Normalizes text for exact-duplicate detection only.
  ///
  /// Trims, collapses internal whitespace, lowercases. Does not perform
  /// semantic similarity — similar-but-not-identical strings are preserved.
  static String normalizeForDuplicateDetection(String text) {
    return text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// True when [content] is null or whitespace-only (not meaningful narrative).
  static bool isPresentationEmpty(String? content) {
    return content == null || content.trim().isEmpty;
  }

  static List<StoryProposalSection> _orderedSections(
    List<StoryProposalSection> sections,
  ) {
    final byRole = <StoryBuilderNarrativeRole, List<StoryProposalSection>>{};
    for (final section in sections) {
      byRole.putIfAbsent(section.narrativeRole, () => []).add(section);
    }

    final ordered = <StoryProposalSection>[];
    for (final role in canonicalRoleOrder) {
      final group = byRole.remove(role);
      if (group == null) continue;
      // Preserve relative order within the same role if multiples exist.
      ordered.addAll(group);
    }
    // Any unexpected roles not in the enum (should not happen) append last.
    for (final remaining in byRole.values) {
      ordered.addAll(remaining);
    }
    return ordered;
  }

  /// Assembles coherent narrative from populated sections.
  ///
  /// Omits skipped, empty, and whitespace-only sections from presentation.
  /// Drops later exact-normalized duplicates (first occurrence wins).
  /// Never invents transition text or paraphrases Hero words.
  static String? _assembleNarrative(List<StoryProposalSection> sections) {
    final parts = <String>[];
    final seenNormalized = <String>{};

    for (final section in sections) {
      if (section.wasSkipped) continue;
      if (isPresentationEmpty(section.content)) continue;

      final content = section.content!;
      final normalized = normalizeForDuplicateDetection(content);
      if (normalized.isEmpty) continue;
      if (seenNormalized.contains(normalized)) continue;

      // Hero-authored content is included verbatim — never rewritten.
      if (section.contentOrigin == StoryProposalContentOrigin.heroAuthored ||
          section.contentOrigin == StoryProposalContentOrigin.derived) {
        parts.add(content);
        seenNormalized.add(normalized);
      }
    }

    if (parts.isEmpty) return null;
    return parts.join('\n\n');
  }

  /// Shaped proposals always require review — never silently accepted.
  static StoryProposalLifecycleStatus _lifecycleForShaped(
    StoryProposalLifecycleStatus current,
  ) {
    if (current == StoryProposalLifecycleStatus.accepted ||
        current == StoryProposalLifecycleStatus.rejected ||
        current == StoryProposalLifecycleStatus.draft) {
      return StoryProposalLifecycleStatus.readyForReview;
    }
    return StoryProposalLifecycleStatus.readyForReview;
  }

  /// Collects all source response IDs across sections (order-preserving, unique).
  static List<StoryBuilderResponseId> collectSourceResponseIds(
    Iterable<StoryProposalSection> sections,
  ) {
    final seen = <String>{};
    final ids = <StoryBuilderResponseId>[];
    for (final section in sections) {
      for (final id in section.sourceResponseIds) {
        if (seen.add(id.value)) {
          ids.add(id);
        }
      }
    }
    return ids;
  }
}

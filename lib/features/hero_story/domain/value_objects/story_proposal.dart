import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_section_id.dart';
import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_narrative_role.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_review_decision.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_intent.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal_provenance.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal_review.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal_section.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal_section_edit.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_title.dart';

/// Derived, reviewable candidate Story structure/content (SB.9 / SB.12 / SB.13).
///
/// Not a [Story]. Not a [StoryBuilderSession]. Not [StoryBuilderUnderstanding].
///
/// Identity: each new generation allocates a new [StoryProposalId]. Persisted
/// proposals keep that id across reloads. Never equals session or Story ids.
///
/// SB.12: only explicit [approve] / [reject] / [editHeroContent] operations
/// may change review state. Shaping and generation never approve.
///
/// SB.13: [materializedStoryId] records the canonical Story created from an
/// accepted proposal (idempotency relationship). The Story remains the source
/// of truth; the proposal is not demoted to a Story subtype.
final class StoryProposal extends ValueObject {
  StoryProposal({
    required this.id,
    required this.sessionId,
    required this.intent,
    required this.provenance,
    required this.lifecycle,
    required this.createdAt,
    required this.updatedAt,
    required Iterable<StoryProposalSection> sections,
    this.title,
    this.narrative,
    this.derivedSummary,
    this.materializedStoryId,
    StoryProposalReview? review,
  })  : sections = List.unmodifiable(sections.toList()),
        review = review ?? StoryProposalReview.empty() {
    if (sessionId != provenance.sessionId) {
      throw ArgumentError(
        'StoryProposal.sessionId must match provenance.sessionId.',
      );
    }
    if (this.sections.isEmpty) {
      throw ArgumentError('StoryProposal requires at least one section.');
    }
    for (var i = 0; i < this.sections.length; i++) {
      if (this.sections[i].order != i) {
        throw ArgumentError(
          'Proposal sections must be contiguous from order 0.',
        );
      }
    }
    final summary = derivedSummary?.trim();
    if (summary != null && summary.isEmpty) {
      throw ArgumentError('derivedSummary cannot be blank when provided.');
    }
    if (summary != null && summary.length > maxDerivedSummaryLength) {
      throw ArgumentError(
        'derivedSummary exceeds $maxDerivedSummaryLength chars.',
      );
    }
    final narrativeText = narrative?.trim();
    if (narrativeText != null && narrativeText.isEmpty) {
      throw ArgumentError('narrative cannot be blank when provided.');
    }
    if (materializedStoryId != null &&
        lifecycle != StoryProposalLifecycleStatus.accepted) {
      throw ArgumentError(
        'materializedStoryId may only be set on an accepted proposal.',
      );
    }
  }

  static const int maxDerivedSummaryLength = 1000;

  /// Processing version for deterministic SB.9 construction.
  static const String deterministicProcessingVersion = 'sb9.deterministic.v1';

  /// Processing version after deterministic SB.10 shaping.
  static const String shapedProcessingVersion = 'sb10.deterministic.v1';

  /// Processing version after AI authoring / shaping (SB.11).
  static const String aiShapedProcessingVersion = 'sb11.ai.v1';

  final StoryProposalId id;
  final StoryBuilderSessionId sessionId;

  /// Explicit absence when no defensible title exists (no Builder title field).
  final StoryTitle? title;

  /// Assembled candidate narrative from Hero-authored section content only.
  /// Null when no answered material produced content.
  final String? narrative;

  final List<StoryProposalSection> sections;

  /// Intent snapshot at proposal time (purpose/themes; not mutated).
  final StoryBuilderIntent intent;

  final StoryProposalProvenance provenance;
  final StoryProposalLifecycleStatus lifecycle;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Optional Understanding-derived summary — never treated as Hero text.
  /// May be refined by the Hero during review without changing content origin.
  final String? derivedSummary;

  /// Durable Hero review metadata (SB.12).
  final StoryProposalReview review;

  /// Canonical Story created from this accepted proposal (SB.13), if any.
  final StoryId? materializedStoryId;

  int get sectionCount => sections.length;

  int get populatedSectionCount =>
      sections.where((s) => s.hasSourceMaterial).length;

  int get skippedSectionCount => sections.where((s) => s.wasSkipped).length;

  int get emptySectionCount => sections.where((s) => s.isEmpty).length;

  bool get isAccepted => lifecycle == StoryProposalLifecycleStatus.accepted;

  bool get isRejected => lifecycle == StoryProposalLifecycleStatus.rejected;

  bool get isReadyForReview =>
      lifecycle == StoryProposalLifecycleStatus.readyForReview;

  bool get isMaterialized => materializedStoryId != null;

  StoryProposalSection? sectionForRole(StoryBuilderNarrativeRole role) {
    for (final section in sections) {
      if (section.narrativeRole == role) {
        return section;
      }
    }
    return null;
  }

  StoryProposalSection? sectionById(StoryProposalSectionId sectionId) {
    for (final section in sections) {
      if (section.id == sectionId) {
        return section;
      }
    }
    return null;
  }

  /// Explicit Hero approval — the only path to [accepted].
  ///
  /// Requires [readyForReview]. Does not create a Story.
  StoryProposal approve({DateTime? at}) {
    if (lifecycle == StoryProposalLifecycleStatus.accepted &&
        review.decision == StoryProposalReviewDecision.approved &&
        !review.editedAfterDecision) {
      return this;
    }
    if (lifecycle != StoryProposalLifecycleStatus.readyForReview) {
      throw StateError(
        'Cannot approve a StoryProposal in lifecycle ${lifecycle.name}.',
      );
    }
    if (review.isApprovalStale) {
      // Stale approval after edit still leaves lifecycle readyForReview —
      // re-approval is allowed and records a fresh decision.
    }
    final decidedAt = at ?? DateTime.now();
    return StoryProposal(
      id: id,
      sessionId: sessionId,
      title: title,
      narrative: narrative,
      sections: sections,
      intent: intent,
      provenance: provenance,
      lifecycle: StoryProposalLifecycleStatus.accepted,
      createdAt: createdAt,
      updatedAt: decidedAt,
      derivedSummary: derivedSummary,
      materializedStoryId: null,
      review: review.copyWith(
        decision: StoryProposalReviewDecision.approved,
        reviewedAt: decidedAt,
        editedAfterDecision: false,
      ),
    );
  }

  /// Explicit Hero rejection — the only path to [rejected] from review.
  ///
  /// Proposal remains persisted. Does not create a Story.
  StoryProposal reject({DateTime? at}) {
    if (lifecycle == StoryProposalLifecycleStatus.rejected &&
        review.decision == StoryProposalReviewDecision.rejected &&
        !review.editedAfterDecision) {
      return this;
    }
    if (lifecycle != StoryProposalLifecycleStatus.readyForReview) {
      throw StateError(
        'Cannot reject a StoryProposal in lifecycle ${lifecycle.name}.',
      );
    }
    final decidedAt = at ?? DateTime.now();
    return StoryProposal(
      id: id,
      sessionId: sessionId,
      title: title,
      narrative: narrative,
      sections: sections,
      intent: intent,
      provenance: provenance,
      lifecycle: StoryProposalLifecycleStatus.rejected,
      createdAt: createdAt,
      updatedAt: decidedAt,
      derivedSummary: derivedSummary,
      materializedStoryId: null,
      review: review.copyWith(
        decision: StoryProposalReviewDecision.rejected,
        reviewedAt: decidedAt,
        editedAfterDecision: false,
      ),
    );
  }


  /// Records the canonical Story created from this accepted proposal (SB.13).
  ///
  /// Idempotent when [storyId] matches an existing link. Does not change
  /// lifecycle — failure to materialize must leave the proposal accepted.
  StoryProposal recordMaterializedStory(StoryId storyId, {DateTime? at}) {
    if (lifecycle != StoryProposalLifecycleStatus.accepted) {
      throw StateError(
        'Cannot record materialization unless proposal is accepted.',
      );
    }
    if (materializedStoryId == storyId) {
      return this;
    }
    if (materializedStoryId != null) {
      throw StateError(
        'Proposal ${id.value} is already linked to Story '
        '${materializedStoryId!.value}.',
      );
    }
    final recordedAt = at ?? DateTime.now();
    return StoryProposal(
      id: id,
      sessionId: sessionId,
      title: title,
      narrative: narrative,
      sections: sections,
      intent: intent,
      provenance: provenance,
      lifecycle: lifecycle,
      createdAt: createdAt,
      updatedAt: recordedAt,
      derivedSummary: derivedSummary,
      materializedStoryId: storyId,
      review: review,
    );
  }

  /// Hero content edit during review (SB.12).
  ///
  /// Allowed fields: title, summary ([derivedSummary]), section contents.
  /// Preserves: ids, session, contentOrigin, sourceResponseIds, provenance,
  /// understanding linkage, processing version.
  ///
  /// Editing an [accepted] proposal invalidates approval → [readyForReview].
  /// Editing a [rejected] proposal reopens review → [readyForReview].
  StoryProposal editHeroContent({
    String? title,
    bool updateTitle = false,
    bool clearTitle = false,
    String? summary,
    bool updateSummary = false,
    bool clearSummary = false,
    Iterable<StoryProposalSectionEdit> sectionEdits = const [],
    DateTime? editedAt,
  }) {
    if (lifecycle == StoryProposalLifecycleStatus.draft) {
      throw StateError('Cannot edit a draft StoryProposal.');
    }

    final at = editedAt ?? DateTime.now();
    var nextTitle = this.title;
    var nextSummary = derivedSummary;
    var titleEdited = review.titleHeroEdited;
    var summaryEdited = review.summaryHeroEdited;
    var titleBefore = review.titleBeforeHeroEdit;
    var summaryBefore = review.summaryBeforeHeroEdit;
    var contentChanged = false;

    if (clearTitle || updateTitle) {
      final previousTitle = this.title?.value;
      final StoryTitle? resolvedTitle;
      if (clearTitle) {
        resolvedTitle = null;
      } else {
        final trimmed = title?.trim();
        if (trimmed == null || trimmed.isEmpty) {
          resolvedTitle = null;
        } else {
          resolvedTitle = StoryTitle(trimmed);
        }
      }
      if (resolvedTitle?.value != previousTitle) {
        contentChanged = true;
        if (!titleEdited) {
          titleBefore = previousTitle;
          titleEdited = true;
        }
        nextTitle = resolvedTitle;
      }
    }

    if (clearSummary || updateSummary) {
      final previousSummary = derivedSummary;
      final String? resolvedSummary;
      if (clearSummary) {
        resolvedSummary = null;
      } else {
        final trimmed = summary?.trim();
        if (trimmed == null || trimmed.isEmpty) {
          resolvedSummary = null;
        } else if (trimmed.length > maxDerivedSummaryLength) {
          throw ArgumentError(
            'derivedSummary exceeds $maxDerivedSummaryLength chars.',
          );
        } else {
          resolvedSummary = trimmed;
        }
      }
      if (resolvedSummary != previousSummary) {
        contentChanged = true;
        if (!summaryEdited) {
          summaryBefore = previousSummary;
          summaryEdited = true;
        }
        nextSummary = resolvedSummary;
      }
    }

    final editsById = <StoryProposalSectionId, StoryProposalSectionEdit>{};
    for (final edit in sectionEdits) {
      if (editsById.containsKey(edit.sectionId)) {
        throw ArgumentError(
          'Duplicate section edit for ${edit.sectionId.value}.',
        );
      }
      editsById[edit.sectionId] = edit;
    }

    final nextSections = <StoryProposalSection>[];
    for (final section in sections) {
      final edit = editsById.remove(section.id);
      if (edit == null) {
        nextSections.add(section);
        continue;
      }
      if (section.wasSkipped) {
        throw StateError(
          'Cannot edit skipped section ${section.id.value}.',
        );
      }
      final previousContent = section.content;
      final trimmed = edit.content?.trim();
      final normalized =
          (trimmed == null || trimmed.isEmpty) ? null : trimmed;
      if (normalized != previousContent) {
        contentChanged = true;
        nextSections.add(
          section.withHeroEditedContent(
            newContent: normalized,
            editedAt: at,
          ),
        );
      } else {
        nextSections.add(section);
      }
    }

    if (editsById.isNotEmpty) {
      final missing = editsById.keys.map((id) => id.value).join(', ');
      throw ArgumentError(
        'Section edit targets unknown section id(s): $missing.',
      );
    }

    if (!contentChanged) {
      return this;
    }

    final nextNarrative = _assembleNarrative(nextSections);
    final hadDecision = review.hasExplicitDecision;
    final nextLifecycle =
        lifecycle == StoryProposalLifecycleStatus.accepted ||
                lifecycle == StoryProposalLifecycleStatus.rejected
            ? StoryProposalLifecycleStatus.readyForReview
            : lifecycle;

    return StoryProposal(
      id: id,
      sessionId: sessionId,
      title: nextTitle,
      narrative: nextNarrative,
      sections: nextSections,
      intent: intent,
      provenance: provenance,
      lifecycle: nextLifecycle,
      createdAt: createdAt,
      updatedAt: at,
      derivedSummary: nextSummary,
      // Re-approval required after content change; clear materialization link.
      materializedStoryId: null,
      review: review.copyWith(
        revision: review.revision + 1,
        // Keep prior decision for stale-approval detection; lifecycle returns
        // to readyForReview so the Hero must explicitly approve again.
        editedAfterDecision: hadDecision || review.editedAfterDecision,
        lastEditedAt: at,
        titleHeroEdited: titleEdited,
        summaryHeroEdited: summaryEdited,
        titleBeforeHeroEdit: titleBefore,
        summaryBeforeHeroEdit: summaryBefore,
      ),
    );
  }

  /// Explicitly begins a Hero revision of an accepted or rejected proposal.
  ///
  /// Transitions to [readyForReview] so prior approval cannot apply to
  /// subsequent content. No-op when already ready for review.
  StoryProposal beginHeroRevision({DateTime? at}) {
    if (lifecycle == StoryProposalLifecycleStatus.readyForReview) {
      return this;
    }
    if (lifecycle != StoryProposalLifecycleStatus.accepted &&
        lifecycle != StoryProposalLifecycleStatus.rejected) {
      throw StateError(
        'Cannot begin revision from lifecycle ${lifecycle.name}.',
      );
    }
    final revisedAt = at ?? DateTime.now();
    return StoryProposal(
      id: id,
      sessionId: sessionId,
      title: title,
      narrative: narrative,
      sections: sections,
      intent: intent,
      provenance: provenance,
      lifecycle: StoryProposalLifecycleStatus.readyForReview,
      createdAt: createdAt,
      updatedAt: revisedAt,
      derivedSummary: derivedSummary,
      materializedStoryId: null,
      review: review.copyWith(
        editedAfterDecision: true,
        lastEditedAt: revisedAt,
      ),
    );
  }

  /// Reopens a rejected proposal for further editing (explicit flow).
  StoryProposal reopenForReview({DateTime? at}) {
    return beginHeroRevision(at: at);
  }

  static String? _assembleNarrative(List<StoryProposalSection> sections) {
    final parts = <String>[];
    for (final section in sections) {
      final content = section.content?.trim();
      if (content == null || content.isEmpty) continue;
      parts.add(content);
    }
    if (parts.isEmpty) return null;
    return parts.join('\n\n');
  }

  /// Content equivalence excluding identity and timestamps (for determinism).
  bool isContentEquivalentTo(StoryProposal other) {
    if (sessionId != other.sessionId) return false;
    if (title != other.title) return false;
    if (narrative != other.narrative) return false;
    if (intent != other.intent) return false;
    if (lifecycle != other.lifecycle) return false;
    if (derivedSummary != other.derivedSummary) return false;
    if (materializedStoryId != other.materializedStoryId) return false;
    if (provenance.derivationKind != other.provenance.derivationKind) {
      return false;
    }
    if (provenance.processingVersion != other.provenance.processingVersion) {
      return false;
    }
    if (review.decision != other.review.decision) return false;
    if (review.revision != other.review.revision) return false;
    if (review.editedAfterDecision != other.review.editedAfterDecision) {
      return false;
    }
    if (sections.length != other.sections.length) return false;
    for (var i = 0; i < sections.length; i++) {
      final a = sections[i];
      final b = other.sections[i];
      if (a.narrativeRole != b.narrativeRole ||
          a.order != b.order ||
          a.content != b.content ||
          a.wasSkipped != b.wasSkipped ||
          a.contentOrigin != b.contentOrigin ||
          a.heroEdited != b.heroEdited ||
          a.contentBeforeHeroEdit != b.contentBeforeHeroEdit ||
          a.sourceResponseIds.length != b.sourceResponseIds.length) {
        return false;
      }
      for (var j = 0; j < a.sourceResponseIds.length; j++) {
        if (a.sourceResponseIds[j] != b.sourceResponseIds[j]) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  List<Object?> get equalityProps => [
    id,
    sessionId,
    title,
    narrative,
    intent,
    provenance,
    lifecycle,
    createdAt,
    updatedAt,
    derivedSummary,
    materializedStoryId,
    review,
    ...sections,
  ];
}

import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_section_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sessionId = StoryBuilderSessionId('session-sb12');
  final responseId = StoryBuilderResponseId('response-1');
  final decidedAt = DateTime.utc(2026, 9, 22, 12);
  final editedAt = DateTime.utc(2026, 9, 22, 13);

  StoryProposalSection heroSection({
    String content = 'I showed up every morning.',
    StoryProposalContentOrigin origin = StoryProposalContentOrigin.heroAuthored,
  }) {
    return StoryProposalSection(
      id: StoryProposalSectionId('section-beginning'),
      narrativeRole: StoryBuilderNarrativeRole.beginning,
      order: 0,
      contentOrigin: origin,
      content: content,
      sourceResponseIds: [responseId],
    );
  }

  StoryProposalSection derivedSection({
    String content = 'AI polished wording from the Hero.',
  }) {
    return StoryProposalSection(
      id: StoryProposalSectionId('section-challenge'),
      narrativeRole: StoryBuilderNarrativeRole.challenge,
      order: 1,
      contentOrigin: StoryProposalContentOrigin.derived,
      content: content,
      sourceResponseIds: [responseId],
    );
  }

  StoryProposal readyProposal({
    List<StoryProposalSection>? sections,
    StoryTitle? title,
    String? derivedSummary,
  }) {
    final secs = sections ?? [heroSection(), derivedSection()];
    return StoryProposal(
      id: StoryProposalId('proposal-sb12'),
      sessionId: sessionId,
      title: title ?? StoryTitle('Morning Resolve'),
      narrative: secs
          .where((s) => s.content != null)
          .map((s) => s.content!)
          .join('\n\n'),
      sections: secs,
      intent: StoryBuilderIntent.empty(),
      provenance: StoryProposalProvenance(
        sessionId: sessionId,
        derivationKind: StoryProposalDerivationKind.deterministic,
        processingVersion: StoryProposal.shapedProcessingVersion,
        understandingKind: StoryBuilderUnderstandingKind.deterministic,
        understandingProcessingVersion: 'sb8.deterministic.v1',
      ),
      lifecycle: StoryProposalLifecycleStatus.readyForReview,
      createdAt: DateTime.utc(2026, 9, 22, 10),
      updatedAt: DateTime.utc(2026, 9, 22, 11),
      derivedSummary: derivedSummary ?? 'A summary of resolve.',
    );
  }

  group('approval', () {
    test('readyForReview can be approved', () {
      final approved = readyProposal().approve(at: decidedAt);
      expect(approved.lifecycle, StoryProposalLifecycleStatus.accepted);
      expect(
        approved.review.decision,
        StoryProposalReviewDecision.approved,
      );
      expect(approved.review.reviewedAt, decidedAt);
      expect(approved.review.editedAfterDecision, isFalse);
    });

    test('approval requires explicit domain operation', () {
      final proposal = readyProposal();
      expect(proposal.lifecycle, StoryProposalLifecycleStatus.readyForReview);
      expect(proposal.review.decision, isNull);
    });

    test('already rejected proposal cannot be approved', () {
      final rejected = readyProposal().reject(at: decidedAt);
      expect(
        () => rejected.approve(at: decidedAt.add(const Duration(minutes: 1))),
        throwsStateError,
      );
      expect(rejected.lifecycle, StoryProposalLifecycleStatus.rejected);
    });

    test('already accepted proposal is idempotent when unchanged', () {
      final approved = readyProposal().approve(at: decidedAt);
      final again = approved.approve(at: decidedAt.add(const Duration(hours: 1)));
      expect(identical(approved, again) || again.review.reviewedAt == decidedAt,
          isTrue);
      expect(again.lifecycle, StoryProposalLifecycleStatus.accepted);
    });
  });

  group('rejection', () {
    test('readyForReview can be rejected and decision persists on object', () {
      final rejected = readyProposal().reject(at: decidedAt);
      expect(rejected.lifecycle, StoryProposalLifecycleStatus.rejected);
      expect(
        rejected.review.decision,
        StoryProposalReviewDecision.rejected,
      );
      expect(rejected.review.reviewedAt, decidedAt);
    });

    test('rejected proposal does not become accepted implicitly', () {
      final rejected = readyProposal().reject(at: decidedAt);
      expect(rejected.lifecycle, isNot(StoryProposalLifecycleStatus.accepted));
      expect(
        rejected.review.decision,
        isNot(StoryProposalReviewDecision.approved),
      );
    });
  });

  group('editing', () {
    test('Hero can edit title, summary, and sections', () {
      final proposal = readyProposal();
      final challenge = proposal.sections[1];
      final edited = proposal.editHeroContent(
        title: 'New Title',
        updateTitle: true,
        summary: 'New summary text',
        updateSummary: true,
        sectionEdits: [
          StoryProposalSectionEdit(
            sectionId: challenge.id,
            content: 'Hero revised the challenge.',
          ),
        ],
        editedAt: editedAt,
      );

      expect(edited.title?.value, 'New Title');
      expect(edited.derivedSummary, 'New summary text');
      expect(edited.sections[1].content, 'Hero revised the challenge.');
      expect(edited.lifecycle, StoryProposalLifecycleStatus.readyForReview);
      expect(edited.review.revision, 1);
      expect(edited.review.lastEditedAt, editedAt);
      expect(edited.review.titleHeroEdited, isTrue);
      expect(edited.review.summaryHeroEdited, isTrue);
      expect(edited.review.titleBeforeHeroEdit, 'Morning Resolve');
      expect(edited.review.summaryBeforeHeroEdit, 'A summary of resolve.');
    });

    test('editing preserves source response IDs and content origin', () {
      final proposal = readyProposal();
      final derived = proposal.sections[1];
      final edited = proposal.editHeroContent(
        sectionEdits: [
          StoryProposalSectionEdit(
            sectionId: derived.id,
            content: 'Edited AI wording.',
          ),
        ],
        editedAt: editedAt,
      );

      final section = edited.sections[1];
      expect(section.contentOrigin, StoryProposalContentOrigin.derived);
      expect(section.sourceResponseIds, [responseId]);
      expect(section.heroEdited, isTrue);
      expect(section.contentBeforeHeroEdit, 'AI polished wording from the Hero.');
      expect(section.id, derived.id);
    });

    test('editing preserves session and understanding provenance', () {
      final proposal = readyProposal();
      final edited = proposal.editHeroContent(
        title: 'Changed',
        updateTitle: true,
        editedAt: editedAt,
      );

      expect(edited.sessionId, sessionId);
      expect(edited.id, proposal.id);
      expect(
        edited.provenance.processingVersion,
        proposal.provenance.processingVersion,
      );
      expect(
        edited.provenance.understandingKind,
        StoryBuilderUnderstandingKind.deterministic,
      );
      expect(
        edited.provenance.understandingProcessingVersion,
        'sb8.deterministic.v1',
      );
      expect(
        edited.provenance.derivationKind,
        StoryProposalDerivationKind.deterministic,
      );
    });

    test('editing invalidates stale approval', () {
      final approved = readyProposal().approve(at: decidedAt);
      final edited = approved.editHeroContent(
        title: 'After approval',
        updateTitle: true,
        editedAt: editedAt,
      );

      expect(edited.lifecycle, StoryProposalLifecycleStatus.readyForReview);
      expect(edited.review.isApprovalStale, isTrue);
      expect(
        edited.review.decision,
        StoryProposalReviewDecision.approved,
      );
      expect(edited.review.editedAfterDecision, isTrue);
    });

    test('beginHeroRevision invalidates accepted without content change', () {
      final approved = readyProposal().approve(at: decidedAt);
      final revising = approved.beginHeroRevision(at: editedAt);
      expect(revising.lifecycle, StoryProposalLifecycleStatus.readyForReview);
      expect(revising.review.editedAfterDecision, isTrue);
      expect(revising.title, approved.title);
    });

    test('sourceResponseIds cannot change through edit operation', () {
      final proposal = readyProposal();
      final edited = proposal.editHeroContent(
        sectionEdits: [
          StoryProposalSectionEdit(
            sectionId: proposal.sections.first.id,
            content: 'New hero text',
          ),
        ],
        editedAt: editedAt,
      );
      expect(
        edited.sections.first.sourceResponseIds,
        proposal.sections.first.sourceResponseIds,
      );
    });
  });

  group('provenance', () {
    test('Hero-authored remains distinguishable from AI-derived after edit', () {
      final proposal = readyProposal();
      final edited = proposal.editHeroContent(
        sectionEdits: [
          StoryProposalSectionEdit(
            sectionId: proposal.sections[0].id,
            content: 'Updated hero words',
          ),
          StoryProposalSectionEdit(
            sectionId: proposal.sections[1].id,
            content: 'Updated AI words',
          ),
        ],
        editedAt: editedAt,
      );

      expect(
        edited.sections[0].contentOrigin,
        StoryProposalContentOrigin.heroAuthored,
      );
      expect(
        edited.sections[1].contentOrigin,
        StoryProposalContentOrigin.derived,
      );
      expect(edited.sections[0].heroEdited, isTrue);
      expect(edited.sections[1].heroEdited, isTrue);
    });
  });

  group('shaping never approves', () {
    test('deterministic shaper leaves lifecycle readyForReview', () {
      final shaped = const DeterministicStoryShaper().shapeSync(
        readyProposal(),
        shapedAt: decidedAt,
      );
      expect(shaped.lifecycle, StoryProposalLifecycleStatus.readyForReview);
      expect(shaped.review.decision, isNull);
    });
  });
}

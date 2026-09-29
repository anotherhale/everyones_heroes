import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_prompt_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_section_id.dart';
import 'package:everyonesheroes/features/hero_story/application/mappers/story_proposal_narrative_resolver.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sessionId = StoryBuilderSessionId('session-1');
  final heroId = HeroId('hero-1');
  final responseId = StoryBuilderResponseId('resp-1');
  final promptId = StoryBuilderPromptId('prompt-1');

  StoryProposal proposal({
    String? narrative,
    String? sectionContent,
    List<StoryBuilderResponseId>? sourceIds,
  }) {
    return StoryProposal(
      id: StoryProposalId('prop-1'),
      sessionId: sessionId,
      narrative: narrative,
      sections: [
        StoryProposalSection(
          id: StoryProposalSectionId('sec-1'),
          narrativeRole: StoryBuilderNarrativeRole.beginning,
          order: 0,
          contentOrigin: StoryProposalContentOrigin.heroAuthored,
          content: sectionContent,
          sourceResponseIds: sourceIds ?? [responseId],
        ),
      ],
      intent: StoryBuilderIntent.empty(),
      provenance: StoryProposalProvenance(
        sessionId: sessionId,
        derivationKind: StoryProposalDerivationKind.deterministic,
        processingVersion: StoryProposal.deterministicProcessingVersion,
      ),
      lifecycle: StoryProposalLifecycleStatus.readyForReview,
      createdAt: DateTime.utc(2026, 9, 22),
      updatedAt: DateTime.utc(2026, 9, 22),
    );
  }

  StoryBuilderSession sessionWithAnswer(String text) {
    return StoryBuilderSession(
      id: sessionId,
      heroId: heroId,
      status: StoryBuilderSessionStatus.completed,
      mode: StoryBuilderMode.guided,
      intent: StoryBuilderIntent.empty(),
      createdAt: DateTime.utc(2026, 9, 22),
      updatedAt: DateTime.utc(2026, 9, 22),
      prompts: [
        StoryBuilderPrompt(
          id: promptId,
          text: 'What happened at the beginning?',
          ordinal: 0,
          narrativeRole: StoryBuilderNarrativeRole.beginning,
        ),
      ],
      responses: [
        StoryBuilderResponse(
          id: responseId,
          promptId: promptId,
          ordinal: 0,
          text: text,
          createdAt: DateTime.utc(2026, 9, 22),
        ),
      ],
    );
  }

  test('prefers explicit proposal narrative', () {
    final resolved = StoryProposalNarrativeResolver.resolve(
      proposal: proposal(
        narrative: 'Explicit narrative.',
        sectionContent: 'Section content.',
      ),
      session: sessionWithAnswer('Session answer.'),
    );
    expect(resolved, 'Explicit narrative.');
  });

  test('falls back to section content when narrative is null', () {
    final resolved = StoryProposalNarrativeResolver.resolve(
      proposal: proposal(sectionContent: 'Section-only material.'),
      session: sessionWithAnswer('Session answer.'),
    );
    expect(resolved, 'Section-only material.');
  });

  test('falls back to linked session answers when sections are empty', () {
    final resolved = StoryProposalNarrativeResolver.resolve(
      proposal: proposal(sectionContent: null),
      session: sessionWithAnswer('Canonical session answer.'),
    );
    expect(resolved, 'Canonical session answer.');
  });

  test('returns null when proposal and session material are empty', () {
    final emptySession = StoryBuilderSession(
      id: sessionId,
      heroId: heroId,
      status: StoryBuilderSessionStatus.completed,
      mode: StoryBuilderMode.guided,
      intent: StoryBuilderIntent.empty(),
      createdAt: DateTime.utc(2026, 9, 22),
      updatedAt: DateTime.utc(2026, 9, 22),
    );
    final resolved = StoryProposalNarrativeResolver.resolve(
      proposal: proposal(sectionContent: null),
      session: emptySession,
    );
    expect(resolved, isNull);
  });

  test('does not use derivedSummary as narrative content', () {
    final withSummary = StoryProposal(
      id: StoryProposalId('prop-2'),
      sessionId: sessionId,
      narrative: null,
      sections: [
        StoryProposalSection(
          id: StoryProposalSectionId('sec-1'),
          narrativeRole: StoryBuilderNarrativeRole.beginning,
          order: 0,
          contentOrigin: StoryProposalContentOrigin.derived,
          content: null,
          sourceResponseIds: [responseId],
        ),
      ],
      intent: StoryBuilderIntent.empty(),
      provenance: StoryProposalProvenance(
        sessionId: sessionId,
        derivationKind: StoryProposalDerivationKind.aiShaped,
        processingVersion: StoryProposal.aiShapedProcessingVersion,
      ),
      lifecycle: StoryProposalLifecycleStatus.readyForReview,
      createdAt: DateTime.utc(2026, 9, 22),
      updatedAt: DateTime.utc(2026, 9, 22),
      derivedSummary: 'AI-only summary must not materialize.',
    );

    final resolved = StoryProposalNarrativeResolver.resolve(
      proposal: withSummary,
      session: sessionWithAnswer('Hero session words.'),
    );
    expect(resolved, 'Hero session words.');
    expect(resolved, isNot(contains('AI-only summary')));
  });
}

import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const builder = DeterministicStoryStructureBuilder();

  StoryBuilderSession emptySession() {
    return StoryBuilderSession.create(
      id: StoryBuilderSessionId.generate(),
      heroId: HeroId.generate(),
      mode: StoryBuilderMode.guided,
    )..pullDomainEvents();
  }

  void presentAll(StoryBuilderSession session) {
    for (final prompt in DeterministicStoryBuilderCatalog.prompts) {
      session.presentPrompt(prompt);
    }
  }

  group('DeterministicStoryStructureBuilder', () {
    test('maps all 11 narrative roles in stable order', () {
      final session = emptySession();
      presentAll(session);
      for (final prompt in DeterministicStoryBuilderCatalog.prompts) {
        session.answerPrompt(
          responseId: StoryBuilderResponseId.generate(),
          promptId: prompt.id,
          text: 'Hero material for ${prompt.narrativeRole!.name}',
        );
      }

      final structure = builder.build(session);

      expect(structure.sectionCount, 11);
      expect(
        structure.sections.map((s) => s.narrativeRole).toList(),
        [
          StoryBuilderNarrativeRole.beginning,
          StoryBuilderNarrativeRole.challenge,
          StoryBuilderNarrativeRole.importance,
          StoryBuilderNarrativeRole.struggle,
          StoryBuilderNarrativeRole.stakes,
          StoryBuilderNarrativeRole.turningPoint,
          StoryBuilderNarrativeRole.decision,
          StoryBuilderNarrativeRole.action,
          StoryBuilderNarrativeRole.outcome,
          StoryBuilderNarrativeRole.reflection,
          StoryBuilderNarrativeRole.message,
        ],
      );
      expect(
        structure.sections.map((s) => s.order).toList(),
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
      );
      expect(
        structure.sections.map((s) => s.promptId.value).toList(),
        [
          'sb.q.beginning',
          'sb.q.challenge',
          'sb.q.importance',
          'sb.q.struggle',
          'sb.q.stakes',
          'sb.q.turningPoint',
          'sb.q.decision',
          'sb.q.action',
          'sb.q.outcome',
          'sb.q.reflection',
          'sb.q.message',
        ],
      );
      expect(structure.populatedSectionCount, 11);
      expect(structure.skippedSectionCount, 0);
      expect(structure.emptySectionCount, 0);
    });

    test('empty session yields 11 empty sections with no fabricated material', () {
      final session = emptySession();
      final structure = builder.build(session);

      expect(structure.sessionId, session.id);
      expect(structure.sectionCount, 11);
      expect(structure.populatedSectionCount, 0);
      expect(structure.skippedSectionCount, 0);
      expect(structure.emptySectionCount, 11);
      for (final section in structure.sections) {
        expect(section.sourceResponseIds, isEmpty);
        expect(section.hasSourceMaterial, isFalse);
        expect(section.wasSkipped, isFalse);
        expect(section.isEmpty, isTrue);
      }
    });

    test('partial answers leave gaps for unanswered roles', () {
      final session = emptySession();
      presentAll(session);

      final beginningId = StoryBuilderResponseId.generate();
      final challengeId = StoryBuilderResponseId.generate();
      final turningPointId = StoryBuilderResponseId.generate();

      session.answerPrompt(
        responseId: beginningId,
        promptId: DeterministicStoryBuilderCatalog.beginningId,
        text: 'It started quietly.',
      );
      session.answerPrompt(
        responseId: challengeId,
        promptId: DeterministicStoryBuilderCatalog.challengeId,
        text: 'I faced a hard choice.',
      );
      session.answerPrompt(
        responseId: turningPointId,
        promptId: DeterministicStoryBuilderCatalog.turningPointId,
        text: 'Something shifted.',
      );

      final structure = builder.build(session);

      expect(structure.populatedSectionCount, 3);
      expect(structure.emptySectionCount, 8);
      expect(structure.skippedSectionCount, 0);

      expect(
        structure.sectionForRole(StoryBuilderNarrativeRole.beginning)!
            .sourceResponseIds,
        [beginningId],
      );
      expect(
        structure.sectionForRole(StoryBuilderNarrativeRole.challenge)!
            .sourceResponseIds,
        [challengeId],
      );
      expect(
        structure.sectionForRole(StoryBuilderNarrativeRole.turningPoint)!
            .sourceResponseIds,
        [turningPointId],
      );
      expect(
        structure.sectionForRole(StoryBuilderNarrativeRole.importance)!.isEmpty,
        isTrue,
      );
      expect(
        structure.sectionForRole(StoryBuilderNarrativeRole.struggle)!.isEmpty,
        isTrue,
      );
    });

    test('skipped prompts produce skipped sections with provenance, not content', () {
      final session = emptySession();
      presentAll(session);

      final beginningId = StoryBuilderResponseId.generate();
      final importanceSkipId = StoryBuilderResponseId.generate();
      final stakesSkipId = StoryBuilderResponseId.generate();

      session.answerPrompt(
        responseId: beginningId,
        promptId: DeterministicStoryBuilderCatalog.beginningId,
        text: 'Beginning words.',
      );
      session.skipPrompt(
        responseId: importanceSkipId,
        promptId: DeterministicStoryBuilderCatalog.importanceId,
      );
      session.skipPrompt(
        responseId: stakesSkipId,
        promptId: DeterministicStoryBuilderCatalog.stakesId,
      );

      final structure = builder.build(session);

      final beginning =
          structure.sectionForRole(StoryBuilderNarrativeRole.beginning)!;
      expect(beginning.hasSourceMaterial, isTrue);
      expect(beginning.wasSkipped, isFalse);
      expect(beginning.sourceResponseIds, [beginningId]);

      final importance =
          structure.sectionForRole(StoryBuilderNarrativeRole.importance)!;
      expect(importance.wasSkipped, isTrue);
      expect(importance.hasSourceMaterial, isFalse);
      expect(importance.isEmpty, isFalse);
      expect(importance.sourceResponseIds, [importanceSkipId]);

      final stakes =
          structure.sectionForRole(StoryBuilderNarrativeRole.stakes)!;
      expect(stakes.wasSkipped, isTrue);
      expect(stakes.hasSourceMaterial, isFalse);
      expect(stakes.sourceResponseIds, [stakesSkipId]);

      expect(structure.populatedSectionCount, 1);
      expect(structure.skippedSectionCount, 2);
      expect(structure.emptySectionCount, 8);
    });

    test('provenance points to correct response IDs; edits keep same ID', () {
      final session = emptySession();
      presentAll(session);

      final challengeResponseId = StoryBuilderResponseId.generate();
      session.answerPrompt(
        responseId: challengeResponseId,
        promptId: DeterministicStoryBuilderCatalog.challengeId,
        text: 'First challenge answer.',
      );

      var structure = builder.build(session);
      expect(
        structure.sectionForRole(StoryBuilderNarrativeRole.challenge)!
            .sourceResponseIds,
        [challengeResponseId],
      );

      session.editResponse(
        responseId: challengeResponseId,
        text: 'Edited challenge answer — still Hero-authored.',
      );

      structure = builder.build(session);
      final challenge =
          structure.sectionForRole(StoryBuilderNarrativeRole.challenge)!;
      expect(challenge.sourceResponseIds, [challengeResponseId]);
      expect(challenge.hasSourceMaterial, isTrue);

      final live = session.responses
          .firstWhere((r) => r.id == challengeResponseId);
      expect(live.text, 'Edited challenge answer — still Hero-authored.');
      expect(live.isEdited, isTrue);
    });

    test('includes session intent without branching structure on themes', () {
      final session = emptySession();
      session.setIntent(
        StoryBuilderIntent(
          purpose: StoryBuilderPurpose.inspireSomeone,
          themes: const [
            StoryBuilderTheme.courage,
            StoryBuilderTheme.perseverance,
          ],
        ),
      );
      presentAll(session);
      session.answerPrompt(
        responseId: StoryBuilderResponseId.generate(),
        promptId: DeterministicStoryBuilderCatalog.messageId,
        text: 'Keep going.',
      );

      final structure = builder.build(session);

      expect(structure.intent.purpose, StoryBuilderPurpose.inspireSomeone);
      expect(
        structure.intent.themes,
        [StoryBuilderTheme.courage, StoryBuilderTheme.perseverance],
      );
      expect(structure.sectionCount, 11);
      expect(
        structure.sections.map((s) => s.narrativeRole).toList(),
        DeterministicStoryBuilderCatalog.prompts
            .map((p) => p.narrativeRole)
            .toList(),
      );
    });

    test('completed session with mix of answers and skips builds fully', () {
      final session = emptySession();
      presentAll(session);
      final responseIds = <StoryBuilderResponseId>[];
      for (var i = 0; i < DeterministicStoryBuilderCatalog.length; i++) {
        final prompt = DeterministicStoryBuilderCatalog.prompts[i];
        final id = StoryBuilderResponseId.generate();
        responseIds.add(id);
        if (i.isOdd) {
          session.skipPrompt(responseId: id, promptId: prompt.id);
        } else {
          session.answerPrompt(
            responseId: id,
            promptId: prompt.id,
            text: 'Answer $i',
          );
        }
      }
      session.complete();

      final structure = builder.build(session);

      expect(session.status, StoryBuilderSessionStatus.completed);
      expect(structure.populatedSectionCount, 6);
      expect(structure.skippedSectionCount, 5);
      expect(structure.emptySectionCount, 0);
      for (var i = 0; i < 11; i++) {
        expect(structure.sections[i].sourceResponseIds, [responseIds[i]]);
        expect(structure.sections[i].wasSkipped, i.isOdd);
        expect(structure.sections[i].hasSourceMaterial, i.isEven);
      }
    });
  });

  group('DeterministicStoryStructureSection', () {
    test('skipped section requires provenance response id', () {
      expect(
        () => DeterministicStoryStructureSection(
          narrativeRole: StoryBuilderNarrativeRole.challenge,
          order: 1,
          promptId: DeterministicStoryBuilderCatalog.challengeId,
          wasSkipped: true,
        ),
        throwsArgumentError,
      );
    });
  });
}

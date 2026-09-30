import 'package:everyonesheroes/core/ids/story_builder_script_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/generate_story_builder_script_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_script_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_session_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_builder_script_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_builder_session_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_script_generator.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_script.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_script_provenance.dart';

/// Generates a durable, non-authoritative Story Script from a session (SB.8).
///
/// Flow: load session → verify material → invoke [StoryScriptGenerator] →
/// validate → persist draft. Never mutates the session. Never auto-approves.
/// AI failure leaves the session intact.
final class GenerateStoryBuilderScriptUseCase
    implements UseCase<GenerateStoryBuilderScriptRequest, StoryBuilderScript> {
  const GenerateStoryBuilderScriptUseCase({
    required StoryBuilderSessionRepository sessionRepository,
    required StoryBuilderScriptRepository scriptRepository,
    required StoryScriptGenerator scriptGenerator,
  })  : _sessionRepository = sessionRepository,
        _scriptRepository = scriptRepository,
        _scriptGenerator = scriptGenerator;

  final StoryBuilderSessionRepository _sessionRepository;
  final StoryBuilderScriptRepository _scriptRepository;
  final StoryScriptGenerator _scriptGenerator;

  @override
  Future<Result<StoryBuilderScript>> execute(
    GenerateStoryBuilderScriptRequest request,
  ) async {
    try {
      final session = await _sessionRepository.findById(request.sessionId);
      if (session == null) {
        return Failure(
          'Story Builder session ${request.sessionId} not found.',
        );
      }

      if (session.status == StoryBuilderSessionStatus.abandoned) {
        return const Failure(
          'Cannot generate a script for an abandoned Story Builder session.',
        );
      }

      final material = _collectMaterial(session, request.language);
      if (material.answers.isEmpty) {
        return Failure(
          'Story Builder session ${session.id} has no answered material '
          'for script generation.',
        );
      }

      final latest =
          await _scriptRepository.findLatestBySessionId(session.id);
      if (latest != null &&
          latest.isDraft &&
          latest.heroEdited &&
          !request.confirmDiscardHeroEdits &&
          request.replaceExistingDraft) {
        return const Failure(
          'Regenerating would discard Hero edits. Confirm before replacing.',
        );
      }

      if (latest != null &&
          latest.isDraft &&
          !latest.heroEdited &&
          !request.replaceExistingDraft) {
        // Idempotent: return existing draft when re-invoked without replace.
        return Success(latest);
      }

      final statusBefore = session.status;
      final responseCountBefore = session.responses.length;
      final responseTextsBefore = [
        for (final r in session.responses) r.text,
      ];

      final draft = await _scriptGenerator.generate(material);
      final content = draft.content.trim();
      if (content.isEmpty) {
        return const Failure(
          'Story script generation produced empty narrative content.',
        );
      }

      if (session.status != statusBefore ||
          session.responses.length != responseCountBefore ||
          !_sameList(
            [for (final r in session.responses) r.text],
            responseTextsBefore,
          )) {
        return const Failure(
          'Story script generation must not mutate the Story Builder session.',
        );
      }

      final at = request.createdAt ?? DateTime.now();
      final scriptId = request.scriptId ?? StoryBuilderScriptId.generate();
      final script = StoryBuilderScript(
        id: scriptId,
        sourceStoryBuilderSessionId: session.id,
        content: content,
        language: draft.language,
        provenance: StoryBuilderScriptProvenance(
          sessionId: session.id,
          processingVersion: draft.processingVersion.trim().isEmpty
              ? StoryBuilderScript.aiProcessingVersion
              : draft.processingVersion,
          providerLabel: draft.providerLabel,
          replacedScriptId: latest?.id.value,
        ),
        status: StoryBuilderScriptStatus.draft,
        createdAt: at,
        updatedAt: at,
        isAiGenerated: true,
        heroEdited: false,
      );

      await _scriptRepository.save(script);
      return Success(script);
    } on StoryScriptGeneratorException catch (e) {
      return Failure('Story script generation failed: ${e.message}');
    } catch (e) {
      return Failure('Failed to generate Story Builder script: $e');
    }
  }

  static StoryScriptGenerationMaterial _collectMaterial(
    StoryBuilderSession session,
    LanguageCode? language,
  ) {
    final ordered = [...session.responses]
      ..sort((a, b) => a.ordinal.compareTo(b.ordinal));
    final promptById = {
      for (final prompt in session.prompts) prompt.id: prompt,
    };

    final answers = <StoryScriptSourceAnswer>[];
    for (final response in ordered) {
      if (response.skipped) continue;
      final text = response.text?.trim();
      if (text == null || text.isEmpty) continue;
      final prompt = promptById[response.promptId];
      final question = prompt?.text.trim().isNotEmpty == true
          ? prompt!.text.trim()
          : 'Story Builder response ${response.ordinal + 1}';
      answers.add(
        StoryScriptSourceAnswer(
          question: question,
          answer: text,
          responseId: response.id.value,
        ),
      );
    }

    return StoryScriptGenerationMaterial(
      sessionId: session.id,
      purpose: session.intent.purpose,
      themes: List.unmodifiable(session.intent.themes),
      themesUnsure: session.intent.themesUnsure,
      language: language,
      answers: answers,
    );
  }

  static bool _sameList(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

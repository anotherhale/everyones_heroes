import 'package:everyonesheroes/core/ids/story_builder_prompt_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/understand_story_builder_session_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_session_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_understanding_kind.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_builder_session_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/deterministic_story_builder_understanding_builder.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/deterministic_story_structure_builder.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_builder_understanding_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_builder_understanding_provenance.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/deterministic_story_structure.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_prompt.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_understanding.dart';

/// Derives Story Understanding from a canonical [StoryBuilderSession] (SB.8).
///
/// Never mutates Hero-authored responses, purpose, or themes.
/// Never creates a [Story]. Never marks the session complete.
/// Prefer recomputation — understanding is not persisted.
final class UnderstandStoryBuilderSessionUseCase
    implements
        UseCase<
          UnderstandStoryBuilderSessionRequest,
          StoryBuilderUnderstanding
        > {
  const UnderstandStoryBuilderSessionUseCase({
    required this._sessionRepository,
    this._understandingPort,
    this._structureBuilder = const DeterministicStoryStructureBuilder(),
    this._understandingBuilder =
        const DeterministicStoryBuilderUnderstandingBuilder(),
  });

  final StoryBuilderSessionRepository _sessionRepository;
  final StoryBuilderUnderstandingPort? _understandingPort;
  final DeterministicStoryStructureBuilder _structureBuilder;
  final DeterministicStoryBuilderUnderstandingBuilder _understandingBuilder;

  @override
  Future<Result<StoryBuilderUnderstanding>> execute(
    UnderstandStoryBuilderSessionRequest request,
  ) async {
    try {
      final session = await _sessionRepository.findById(request.sessionId);
      if (session == null) {
        return Failure(
          'Story Builder session ${request.sessionId} not found.',
        );
      }

      if (session.status == StoryBuilderSessionStatus.abandoned) {
        return Failure(
          'Cannot understand an abandoned Story Builder session.',
        );
      }

      final answered = session.responses.where((r) => !r.skipped).toList();
      if (answered.isEmpty) {
        return Failure(
          'Story Builder session ${session.id} has no answered material to analyze.',
        );
      }

      // Snapshot pre-analysis state to prove non-mutation.
      final purposeBefore = session.intent.purpose;
      final themesBefore = List.of(session.intent.themes);
      final responseCountBefore = session.responses.length;
      final storyIdBefore = session.storyId;
      final statusBefore = session.status;

      final structure = _structureBuilder.build(session);
      final analyzedAt = request.analyzedAt ?? DateTime.now();

      final StoryBuilderUnderstanding understanding;
      switch (request.kind) {
        case StoryBuilderUnderstandingKind.deterministic:
          understanding = _understandingBuilder.build(
            session: session,
            structure: structure,
            analyzedAt: analyzedAt,
          );
        case StoryBuilderUnderstandingKind.aiEnhanced:
          understanding = await _buildAiEnhanced(
            session: session,
            structure: structure,
            analyzedAt: analyzedAt,
          );
      }

      // Canonical session must remain unchanged.
      if (session.intent.purpose != purposeBefore ||
          !_sameThemes(session.intent.themes, themesBefore) ||
          session.responses.length != responseCountBefore ||
          session.storyId != storyIdBefore ||
          session.status != statusBefore) {
        return Failure(
          'Story Understanding must not mutate the Story Builder session.',
        );
      }

      return Success(understanding);
    } on StoryBuilderUnderstandingException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return Failure('Failed to understand Story Builder session: $e');
    }
  }

  Future<StoryBuilderUnderstanding> _buildAiEnhanced({
    required StoryBuilderSession session,
    required DeterministicStoryStructure structure,
    required DateTime analyzedAt,
  }) async {
    final port = _understandingPort;
    if (port == null) {
      throw const StoryBuilderUnderstandingException(
        'AI-enhanced Story Understanding is unavailable '
        '(no StoryBuilderUnderstandingPort configured).',
      );
    }

    final draft = await port.analyze(_toRequest(session, structure));
    final validIds = StoryBuilderUnderstandingProvenance.validResponseIds(
      session,
    );
    StoryBuilderUnderstandingProvenance.validateDraft(
      draft: draft,
      validIds: validIds,
    );

    final hasSignal = draft.themes.isNotEmpty ||
        draft.narrativeElements.isNotEmpty ||
        draft.significantEvents.isNotEmpty ||
        !draft.keyElements.isEmpty ||
        (draft.derivedSummary != null &&
            draft.derivedSummary!.trim().isNotEmpty);
    if (!hasSignal) {
      throw const StoryBuilderUnderstandingException(
        'AI Story Understanding returned an empty result.',
      );
    }

    return StoryBuilderUnderstanding(
      sessionId: session.id,
      kind: StoryBuilderUnderstandingKind.aiEnhanced,
      structure: structure,
      intentSnapshot: session.intent,
      processingVersion: draft.promptOrTemplateVersion?.trim().isNotEmpty ==
              true
          ? draft.promptOrTemplateVersion!.trim()
          : StoryBuilderUnderstanding.aiProcessingVersion,
      analyzedAt: analyzedAt,
      themes: draft.themes,
      narrativeElements: draft.narrativeElements,
      keyElements: draft.keyElements,
      significantEvents: draft.significantEvents,
      derivedSummary: draft.derivedSummary,
      providerLabel: draft.providerLabel,
      modelLabel: draft.modelLabel,
    );
  }

  static StoryBuilderUnderstandingRequest _toRequest(
    StoryBuilderSession session,
    DeterministicStoryStructure structure,
  ) {
    final promptById = <StoryBuilderPromptId, StoryBuilderPrompt>{
      for (final prompt in session.prompts) prompt.id: prompt,
    };

    return StoryBuilderUnderstandingRequest(
      purpose: session.intent.purpose,
      themes: session.intent.themes,
      themesUnsure: session.intent.themesUnsure,
      responses: [
        for (final response in session.responses)
          StoryBuilderUnderstandingResponseItem(
            id: response.id,
            ordinal: response.ordinal,
            narrativeRole: promptById[response.promptId]?.narrativeRole,
            text: response.text,
            skipped: response.skipped,
          ),
      ],
      structureSections: [
        for (final section in structure.sections)
          StoryBuilderUnderstandingStructureSection(
            narrativeRole: section.narrativeRole,
            order: section.order,
            sourceResponseIds: section.sourceResponseIds,
            wasSkipped: section.wasSkipped,
            hasSourceMaterial: section.hasSourceMaterial,
          ),
      ],
    );
  }

  static bool _sameThemes(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

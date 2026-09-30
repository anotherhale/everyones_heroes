import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_section_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/bridges/story_builder_theme_narrative_theme_bridge.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/classify_story_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/materialize_story_builder_script_request.dart';
import 'package:everyonesheroes/features/hero_story/application/mappers/story_materialization_mapper.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/classify_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/create_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_script_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_content_origin.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_derivation_kind.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_builder_script_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_builder_session_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_proposal_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/deterministic_story_builder_understanding_builder.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/deterministic_story_structure_builder.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_script.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_classification.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal_provenance.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal_section.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_title.dart';

/// Materializes a canonical [Story] from an **approved** Story Builder script.
///
/// Builds (or reuses) a [StoryProposal] whose narrative is the approved script
/// content and whose title is the Hero-provided [StoryTitle], then creates the
/// Story. Title belongs to Story / StoryProposal — not StoryBuilderSession and
/// not the AI script artifact.
///
/// Retry-safe: failed Create Story leaves the approved script and chosen title
/// intact (title is persisted on the linked proposal).
/// Does not regenerate AI content. Does not revoke script approval.
final class MaterializeStoryBuilderScriptUseCase
    implements UseCase<MaterializeStoryBuilderScriptRequest, Story> {
  MaterializeStoryBuilderScriptUseCase({
    required StoryBuilderScriptRepository scriptRepository,
    required StoryBuilderSessionRepository sessionRepository,
    required StoryProposalRepository proposalRepository,
    required StoryRepository storyRepository,
    required HeroRepository heroRepository,
    required CreateStoryUseCase createStoryUseCase,
    ClassifyStoryUseCase? classifyStoryUseCase,
    DeterministicStoryStructureBuilder structureBuilder =
        const DeterministicStoryStructureBuilder(),
    DeterministicStoryBuilderUnderstandingBuilder understandingBuilder =
        const DeterministicStoryBuilderUnderstandingBuilder(),
    StoryMaterializationMapper mapper = const StoryMaterializationMapper(),
    StoryBuilderThemeNarrativeThemeBridge themeBridge =
        const StoryBuilderThemeNarrativeThemeBridge(),
  })  : _scriptRepository = scriptRepository,
        _sessionRepository = sessionRepository,
        _proposalRepository = proposalRepository,
        _storyRepository = storyRepository,
        _heroRepository = heroRepository,
        _createStoryUseCase = createStoryUseCase,
        _classifyStoryUseCase = classifyStoryUseCase,
        _structureBuilder = structureBuilder,
        _understandingBuilder = understandingBuilder,
        _mapper = mapper,
        _themeBridge = themeBridge;

  final StoryBuilderScriptRepository _scriptRepository;
  final StoryBuilderSessionRepository _sessionRepository;
  final StoryProposalRepository _proposalRepository;
  final StoryRepository _storyRepository;
  final HeroRepository _heroRepository;
  final CreateStoryUseCase _createStoryUseCase;
  final ClassifyStoryUseCase? _classifyStoryUseCase;
  final DeterministicStoryStructureBuilder _structureBuilder;
  final DeterministicStoryBuilderUnderstandingBuilder _understandingBuilder;
  final StoryMaterializationMapper _mapper;
  final StoryBuilderThemeNarrativeThemeBridge _themeBridge;

  @override
  Future<Result<Story>> execute(
    MaterializeStoryBuilderScriptRequest request,
  ) async {
    try {
      var script = await _scriptRepository.findById(request.scriptId);
      if (script == null) {
        return Failure(
          'Story Builder script ${request.scriptId} not found.',
        );
      }

      if (script.status != StoryBuilderScriptStatus.approved) {
        return Failure(
          'Only an approved Story Builder script can create a Story '
          '(status=${script.status.name}).',
        );
      }

      final StoryTitle storyTitle;
      try {
        storyTitle = StoryTitle(request.title);
      } on ArgumentError catch (e) {
        return Failure(
          e.message?.toString() ?? 'Story title is required.',
        );
      }

      final narrative = script.content.trim();
      if (narrative.isEmpty) {
        return const Failure(
          'Cannot materialize a Story from a blank approved script.',
        );
      }

      if (script.materializedStoryId != null) {
        final existing =
            await _storyRepository.findById(script.materializedStoryId!);
        if (existing != null) {
          return Success(existing);
        }
      }

      final session = await _sessionRepository.findById(
        script.sourceStoryBuilderSessionId,
      );
      if (session == null) {
        return Failure(
          'Story Builder session ${script.sourceStoryBuilderSessionId} '
          'not found for script ${script.id}.',
        );
      }

      final hero = await _heroRepository.findById(session.heroId);
      if (hero == null) {
        return Failure('Hero not found: ${session.heroId.value}');
      }
      if (!hero.isActive) {
        return const Failure(
          'Cannot materialize a story for an archived hero.',
        );
      }

      var proposal = await _resolveProposal(
        script: script,
        session: session,
        narrative: narrative,
        title: storyTitle,
        at: request.materializedAt,
      );

      if (proposal.lifecycle != StoryProposalLifecycleStatus.accepted) {
        proposal = proposal.approve(at: request.materializedAt);
        await _proposalRepository.save(proposal);
      }

      if (script.linkedProposalId != proposal.id) {
        script = script.withLinkedProposal(
          proposal.id,
          at: request.materializedAt,
        );
        await _scriptRepository.save(script);
      }

      final originalLanguage = hero.profile.languages.isNotEmpty
          ? hero.profile.languages.first
          : LanguageCode('en');

      final deterministicId =
          StoryMaterializationMapper.storyIdForProposal(proposal.id);

      final existingStory = await _storyRepository.findByStoryProposalId(
            proposal.id,
          ) ??
          await _storyRepository.findById(deterministicId);

      if (existingStory != null) {
        await _linkScriptToStory(script, proposal, existingStory, request);
        return Success(existingStory);
      }

      final createRequest = _mapper.toCreateStoryRequest(
        proposal: proposal,
        heroId: session.heroId,
        originalLanguage: originalLanguage,
        storyId: deterministicId,
        narrativeContent: narrative,
        sourceStoryBuilderScriptId: script.id,
      );

      final createResult = await _createStoryUseCase.execute(createRequest);
      if (createResult is Failure<Story>) {
        return Failure(
          'Failed to create story from approved script: ${createResult.error}',
        );
      }

      var story = (createResult as Success<Story>).value;
      story = await _applyThemeClassification(story, proposal);
      await _linkScriptToStory(script, proposal, story, request);
      return Success(story);
    } catch (e) {
      return Failure('Failed to materialize Story Builder script: $e');
    }
  }

  Future<StoryProposal> _resolveProposal({
    required StoryBuilderScript script,
    required StoryBuilderSession session,
    required String narrative,
    required StoryTitle title,
    DateTime? at,
  }) async {
    if (script.linkedProposalId != null) {
      final existing =
          await _proposalRepository.findById(script.linkedProposalId!);
      if (existing != null &&
          existing.narrative?.trim() == narrative &&
          (existing.lifecycle == StoryProposalLifecycleStatus.accepted ||
              existing.lifecycle ==
                  StoryProposalLifecycleStatus.readyForReview)) {
        final withTitle = existing.withTitle(title, at: at);
        if (withTitle != existing) {
          await _proposalRepository.save(withTitle);
        }
        return withTitle;
      }
    }

    final when = at ?? DateTime.now();
    final structure = _structureBuilder.build(session);
    final understanding = _understandingBuilder.build(
      session: session,
      structure: structure,
      analyzedAt: when,
    );

    final responseById = {
      for (final response in session.responses) response.id: response,
    };

    final sections = <StoryProposalSection>[];
    for (final structureSection in structure.sections) {
      final sourceIds = structureSection.sourceResponseIds;
      String? content;
      if (structureSection.hasSourceMaterial) {
        final texts = <String>[];
        for (final responseId in sourceIds) {
          final response = responseById[responseId];
          if (response == null || response.skipped) continue;
          final text = response.text;
          if (text != null && text.trim().isNotEmpty) {
            texts.add(text);
          }
        }
        if (texts.isNotEmpty) {
          content = texts.join('\n\n');
        }
      }
      sections.add(
        StoryProposalSection(
          id: StoryProposalSectionId.generate(),
          narrativeRole: structureSection.narrativeRole,
          order: structureSection.order,
          contentOrigin: StoryProposalContentOrigin.derived,
          content: content,
          sourceResponseIds: sourceIds,
          wasSkipped: structureSection.wasSkipped,
        ),
      );
    }

    final proposal = StoryProposal(
      id: StoryProposalId.generate(),
      sessionId: session.id,
      title: title,
      narrative: narrative,
      sections: sections,
      intent: session.intent,
      provenance: StoryProposalProvenance(
        sessionId: session.id,
        derivationKind: StoryProposalDerivationKind.aiShaped,
        processingVersion: StoryBuilderScript.aiProcessingVersion,
        understandingKind: understanding.kind,
        understandingProcessingVersion: understanding.processingVersion,
        sourceScriptId: script.id,
      ),
      lifecycle: StoryProposalLifecycleStatus.readyForReview,
      createdAt: when,
      updatedAt: when,
      derivedSummary: understanding.derivedSummary,
    );

    await _proposalRepository.save(proposal);
    return proposal;
  }

  Future<void> _linkScriptToStory(
    StoryBuilderScript script,
    StoryProposal proposal,
    Story story,
    MaterializeStoryBuilderScriptRequest request,
  ) async {
    try {
      if (proposal.materializedStoryId != story.id) {
        final linkedProposal = proposal.recordMaterializedStory(
          story.id,
          at: request.materializedAt,
        );
        await _proposalRepository.save(linkedProposal);
      }
    } catch (_) {
      // Story already exists; proposal link is recoverable via provenance.
    }

    final refreshed = await _scriptRepository.findById(script.id) ?? script;
    var updated = refreshed;
    if (updated.linkedProposalId != proposal.id) {
      updated = updated.withLinkedProposal(
        proposal.id,
        at: request.materializedAt,
      );
    }
    if (updated.materializedStoryId != story.id) {
      updated = updated.recordMaterializedStory(
        story.id,
        at: request.materializedAt,
      );
    }
    if (updated != refreshed) {
      await _scriptRepository.save(updated);
    }
  }

  Future<Story> _applyThemeClassification(
    Story story,
    StoryProposal proposal,
  ) async {
    final themeIds = _themeBridge.mapThemes(proposal.intent.themes);
    final existing = story.classification;
    final classification = StoryClassification(
      subjects: existing.subjects,
      challenges: existing.challenges,
      narrativeThemeIds: themeIds,
      outcomes: existing.outcomes,
      emotionalCharacters: existing.emotionalCharacters,
      audience: existing.audience,
      geography: existing.geography,
    );

    if (_sameThemeIds(existing.narrativeThemeIds, themeIds)) {
      return story;
    }

    final classify = _classifyStoryUseCase;
    if (classify != null) {
      final result = await classify.execute(
        ClassifyStoryRequest(
          storyId: story.id,
          classification: classification,
        ),
      );
      if (result is Success<Story>) {
        return result.value;
      }
      if (result is Failure<Story>) {
        throw StateError(
          'Failed to classify materialized story themes: ${result.error}',
        );
      }
    }

    story.classify(classification);
    await _storyRepository.save(story);
    for (final _ in story.pullDomainEvents()) {}
    return story;
  }

  bool _sameThemeIds(
    List<NarrativeThemeId> a,
    List<NarrativeThemeId> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/bridges/story_builder_theme_narrative_theme_bridge.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/classify_story_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/materialize_story_proposal_request.dart';
import 'package:everyonesheroes/features/hero_story/application/mappers/story_materialization_mapper.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/classify_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/create_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_builder_session_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_proposal_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_classification.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_narrative.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_title.dart';

/// Materializes an accepted [StoryProposal] into a canonical [Story] (SB.13).
///
/// Idempotent: repeated calls return the existing Story.
/// Persistence failure leaves the proposal accepted for retry.
/// Does not publish, submit, or approve the Story.
///
/// HS.FG.2: after create (and on draft refresh), maps Builder intent themes to
/// Discovery [NarrativeThemeId]s and classifies the Story. Does not alter
/// provenance, personalize, or emit behavioral evidence.
final class MaterializeStoryProposalUseCase
    implements UseCase<MaterializeStoryProposalRequest, Story> {
  MaterializeStoryProposalUseCase({
    required StoryProposalRepository proposalRepository,
    required StoryBuilderSessionRepository sessionRepository,
    required StoryRepository storyRepository,
    required HeroRepository heroRepository,
    required CreateStoryUseCase createStoryUseCase,
    ClassifyStoryUseCase? classifyStoryUseCase,
    StoryMaterializationMapper mapper = const StoryMaterializationMapper(),
    StoryBuilderThemeNarrativeThemeBridge themeBridge =
        const StoryBuilderThemeNarrativeThemeBridge(),
  })  : _proposalRepository = proposalRepository,
        _sessionRepository = sessionRepository,
        _storyRepository = storyRepository,
        _heroRepository = heroRepository,
        _createStoryUseCase = createStoryUseCase,
        _classifyStoryUseCase = classifyStoryUseCase,
        _mapper = mapper,
        _themeBridge = themeBridge;

  final StoryProposalRepository _proposalRepository;
  final StoryBuilderSessionRepository _sessionRepository;
  final StoryRepository _storyRepository;
  final HeroRepository _heroRepository;
  final CreateStoryUseCase _createStoryUseCase;
  final ClassifyStoryUseCase? _classifyStoryUseCase;
  final StoryMaterializationMapper _mapper;
  final StoryBuilderThemeNarrativeThemeBridge _themeBridge;

  @override
  Future<Result<Story>> execute(
    MaterializeStoryProposalRequest request,
  ) async {
    try {
      final proposal = await _proposalRepository.findById(request.proposalId);
      if (proposal == null) {
        return Failure(
          'Story Proposal ${request.proposalId} not found.',
        );
      }

      if (proposal.lifecycle != StoryProposalLifecycleStatus.accepted) {
        return Failure(
          'Only accepted StoryProposals can be materialized '
          '(lifecycle=${proposal.lifecycle.name}).',
        );
      }

      // Idempotency Option B — proposal already linked.
      if (proposal.materializedStoryId != null) {
        final existing = await _storyRepository.findById(
          proposal.materializedStoryId!,
        );
        if (existing != null) {
          return Success(existing);
        }
      }

      final deterministicId =
          StoryMaterializationMapper.storyIdForProposal(proposal.id);

      // Existing Story for this proposal (provenance or deterministic id).
      final existing = await _storyRepository.findByStoryProposalId(
            proposal.id,
          ) ??
          await _storyRepository.findById(deterministicId);

      if (existing != null) {
        // Re-approval after revision: refresh draft content in place.
        if (proposal.materializedStoryId == null &&
            existing.lifecycleStatus == StoryLifecycleStatus.draft) {
          final refreshed = await _refreshDraftFromProposal(
            existing,
            proposal,
          );
          await _linkProposalIfNeeded(proposal, refreshed, request);
          return Success(refreshed);
        }
        await _linkProposalIfNeeded(proposal, existing, request);
        return Success(existing);
      }

      final session = await _sessionRepository.findById(proposal.sessionId);
      if (session == null) {
        return Failure(
          'Story Builder session ${proposal.sessionId} not found '
          'for proposal ${proposal.id}.',
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

      final originalLanguage = hero.profile.languages.isNotEmpty
          ? hero.profile.languages.first
          : LanguageCode('en');

      final createRequest = _mapper.toCreateStoryRequest(
        proposal: proposal,
        heroId: session.heroId,
        originalLanguage: originalLanguage,
        storyId: deterministicId,
      );

      final createResult = await _createStoryUseCase.execute(createRequest);
      if (createResult is Failure<Story>) {
        // Proposal remains accepted — retryable.
        return Failure(
          'Failed to create story from proposal: ${createResult.error}',
        );
      }

      var story = (createResult as Success<Story>).value;
      story = await _applyThemeClassification(story, proposal);
      await _linkProposalIfNeeded(proposal, story, request);
      return Success(story);
    } catch (e) {
      return Failure('Failed to materialize Story Proposal: $e');
    }
  }

  Future<Story> _refreshDraftFromProposal(
    Story story,
    StoryProposal proposal,
  ) async {
    final narrativeText = proposal.narrative?.trim();
    if (narrativeText == null || narrativeText.isEmpty) {
      throw ArgumentError(
        'Cannot refresh a Story from a proposal without narrative.',
      );
    }
    story.updateNarrative(
      title: proposal.title ?? StoryTitle('Untitled Story'),
      narrative: StoryNarrative(narrativeText),
    );
    await _storyRepository.save(story);
    for (final _ in story.pullDomainEvents()) {
      // Discard — refresh is not a new StoryCreated fact.
    }
    return _applyThemeClassification(story, proposal);
  }

  /// HS.FG.2: translate Builder intent themes → Discovery NarrativeThemeIds.
  ///
  /// Empty / unsure theme intent leaves classification themes empty.
  /// Other classification dimensions are preserved (themes-only update).
  /// Classification is catalog reference only — provenance is unchanged.
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

    // Skip no-op classify when themes already match.
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

    // Fallback when ClassifyStoryUseCase is not wired (tests / legacy).
    story.classify(classification);
    await _storyRepository.save(story);
    for (final _ in story.pullDomainEvents()) {
      // Event bus optional in this path; ClassifyStoryUseCase is preferred.
    }
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

  Future<void> _linkProposalIfNeeded(
    StoryProposal proposal,
    Story story,
    MaterializeStoryProposalRequest request,
  ) async {
    if (proposal.materializedStoryId == story.id) {
      return;
    }
    try {
      final linked = proposal.recordMaterializedStory(
        story.id,
        at: request.materializedAt,
      );
      await _proposalRepository.save(linked);
    } catch (_) {
      // Story persistence already succeeded. Missing link is recoverable on
      // the next materialize via provenance / deterministic StoryId lookup.
    }
  }
}

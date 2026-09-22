import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/materialize_story_proposal_request.dart';
import 'package:everyonesheroes/features/hero_story/application/mappers/story_materialization_mapper.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/create_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_builder_session_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_proposal_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_narrative.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_title.dart';

/// Materializes an accepted [StoryProposal] into a canonical [Story] (SB.13).
///
/// Idempotent: repeated calls return the existing Story.
/// Persistence failure leaves the proposal accepted for retry.
/// Does not publish, submit, approve, or catalog the Story.
final class MaterializeStoryProposalUseCase
    implements UseCase<MaterializeStoryProposalRequest, Story> {
  MaterializeStoryProposalUseCase({
    required StoryProposalRepository proposalRepository,
    required StoryBuilderSessionRepository sessionRepository,
    required StoryRepository storyRepository,
    required HeroRepository heroRepository,
    required CreateStoryUseCase createStoryUseCase,
    StoryMaterializationMapper mapper = const StoryMaterializationMapper(),
  })  : _proposalRepository = proposalRepository,
        _sessionRepository = sessionRepository,
        _storyRepository = storyRepository,
        _heroRepository = heroRepository,
        _createStoryUseCase = createStoryUseCase,
        _mapper = mapper;

  final StoryProposalRepository _proposalRepository;
  final StoryBuilderSessionRepository _sessionRepository;
  final StoryRepository _storyRepository;
  final HeroRepository _heroRepository;
  final CreateStoryUseCase _createStoryUseCase;
  final StoryMaterializationMapper _mapper;

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

      final story = (createResult as Success<Story>).value;
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
    return story;
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

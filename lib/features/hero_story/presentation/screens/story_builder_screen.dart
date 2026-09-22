import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_mode.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_narrative_role.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_content_origin.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal_section.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal_section_edit.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/resumable_story_builder_sessions_provider.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/story_builder_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/owned_story_detail_screen.dart';

/// Story Builder screen — Guided (SB.3) or AI Story Coach (SB.7).
///
/// Collects Hero-authored responses. AI mode asks adaptive questions; the Hero
/// remains the author. Prefer entering via [StoryBuilderEntryScreen].
class StoryBuilderScreen extends ConsumerStatefulWidget {
  const StoryBuilderScreen({
    super.key,
    this.resumeSessionId,
    this.mode = StoryBuilderMode.guided,
  });

  /// When non-null, loads and resumes that durable session.
  final String? resumeSessionId;

  /// Mode used only when starting a new session without [resumeSessionId].
  final StoryBuilderMode mode;

  @override
  ConsumerState<StoryBuilderScreen> createState() => _StoryBuilderScreenState();
}

class _StoryBuilderScreenState extends ConsumerState<StoryBuilderScreen> {
  final _textController = TextEditingController();
  var _started = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = ref.read(storyBuilderControllerProvider.notifier);
      final resumeId = widget.resumeSessionId;
      if (resumeId != null && resumeId.isNotEmpty) {
        await controller.resumeSession(StoryBuilderSessionId(resumeId));
      } else {
        await controller.startNewSession(mode: widget.mode);
      }
      _syncDraftFromState();
    });
  }

  void _syncDraftFromState() {
    final draft = ref.read(storyBuilderControllerProvider).draftText;
    if (_textController.text != draft) {
      _textController.value = TextEditingValue(
        text: draft,
        selection: TextSelection.collapsed(offset: draft.length),
      );
    }
  }

  Future<void> _pauseAndLeave() async {
    final state = ref.read(storyBuilderControllerProvider);
    if (state.phase == StoryBuilderUiPhase.questioning &&
        state.sessionId != null) {
      await ref.read(storyBuilderControllerProvider.notifier).pause();
      ref.invalidate(resumableStoryBuilderSessionsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(storyBuilderControllerProvider);
    final controller = ref.read(storyBuilderControllerProvider.notifier);

    ref.listen(storyBuilderControllerProvider, (prev, next) {
      if (prev?.draftText != next.draftText &&
          _textController.text != next.draftText &&
          next.phase == StoryBuilderUiPhase.questioning) {
        _textController.value = TextEditingValue(
          text: next.draftText,
          selection: TextSelection.collapsed(offset: next.draftText.length),
        );
      }
    });

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          return;
        }
        await _pauseAndLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(state.isAiMode ? 'AI Story Coach' : 'Build My Story'),
          actions: [
            if (state.phase == StoryBuilderUiPhase.questioning)
              TextButton(
                key: const ValueKey('story-builder-pause'),
                onPressed: state.isBusy
                    ? null
                    : () async {
                        await controller.pause();
                        ref.invalidate(resumableStoryBuilderSessionsProvider);
                        if (context.mounted) {
                          Navigator.of(context).maybePop();
                        }
                      },
                child: const Text('Pause'),
              ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: switch (state.phase) {
              StoryBuilderUiPhase.loading => const Center(
                child: CircularProgressIndicator(
                  key: ValueKey('story-builder-loading'),
                ),
              ),
              StoryBuilderUiPhase.thinking => const _ThinkingBody(),
              StoryBuilderUiPhase.error => _ErrorBody(
                message: state.errorMessage ?? 'Something went wrong.',
                onRetry: () {
                  final resumeId = widget.resumeSessionId;
                  if (resumeId != null && resumeId.isNotEmpty) {
                    controller.resumeSession(StoryBuilderSessionId(resumeId));
                  } else {
                    controller.startNewSession(mode: widget.mode);
                  }
                },
              ),
              StoryBuilderUiPhase.coachUnavailable => _CoachUnavailableBody(
                message: state.errorMessage ??
                    'The AI Story Coach is unavailable right now.',
                onRetry: state.isBusy ? null : () => controller.retryCoach(),
                onContinueGuided: state.isBusy
                    ? null
                    : () => controller.continueWithGuidedBuilder(),
                onBack: () => Navigator.of(context).maybePop(),
              ),
              StoryBuilderUiPhase.authoringUnavailable =>
                _AuthoringUnavailableBody(
                  message: state.errorMessage ??
                      "We couldn't create the AI version of your story. "
                          'Your existing story proposal is still safe.',
                  onRetry:
                      state.isBusy ? null : () => controller.retryAiAuthoring(),
                  onContinueWithCurrent: state.isBusy
                      ? null
                      : () => controller.continueWithCurrentProposal(),
                  onExit: () {
                    ref.invalidate(resumableStoryBuilderSessionsProvider);
                    Navigator.of(context).maybePop();
                  },
                ),
              StoryBuilderUiPhase.completed => _CompletedBody(
                isAiMode: state.isAiMode,
                isBusy: state.isBusy,
                errorMessage: state.errorMessage,
                onBuildProposal: state.isBusy
                    ? null
                    : () => controller.buildStoryProposal(),
                onDone: () {
                  ref.invalidate(resumableStoryBuilderSessionsProvider);
                  Navigator.of(context).maybePop();
                },
              ),
              StoryBuilderUiPhase.storyCreated => _StoryCreatedBody(
                story: state.materializedStory!,
                isBusy: state.isBusy,
                onEdit: state.isBusy
                    ? null
                    : () => controller.beginProposalRevision(),
                onContinueToStory: () {
                  final storyId = state.materializedStory!.id.value;
                  ref.invalidate(resumableStoryBuilderSessionsProvider);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => OwnedStoryDetailScreen(storyId: storyId),
                    ),
                  );
                },
                onDone: () {
                  ref.invalidate(resumableStoryBuilderSessionsProvider);
                  Navigator.of(context).maybePop();
                },
              ),
              StoryBuilderUiPhase.proposalPreview => _ProposalReviewBody(
                proposal: state.displayedProposal!,
                isAiAssisted: state.isAiAssistedProposal &&
                    !state.showingOriginalProposal,
                showingOriginal: state.showingOriginalProposal,
                canCompare: state.canCompareProposals,
                canImproveWithAi: state.canImproveWithAi && !state.isBusy,
                isBusy: state.isBusy,
                errorMessage: state.errorMessage,
                onImproveWithAi: () => controller.improveProposalWithAi(),
                onToggleCompare: () => controller.toggleProposalCompare(),
                onBack: () => controller.leaveProposalPreview(),
                onSaveEdits: ({
                  required String? title,
                  required bool updateTitle,
                  required bool clearTitle,
                  required String? summary,
                  required bool updateSummary,
                  required bool clearSummary,
                  required List<StoryProposalSectionEdit> sectionEdits,
                }) {
                  return controller.saveProposalEdits(
                    title: title,
                    updateTitle: updateTitle,
                    clearTitle: clearTitle,
                    summary: summary,
                    updateSummary: updateSummary,
                    clearSummary: clearSummary,
                    sectionEdits: sectionEdits,
                  );
                },
                onApprove: () => controller.approveProposal(),
                onReject: () => controller.rejectProposal(),
                onBeginRevision: () => controller.beginProposalRevision(),
                onRetryMaterialize: () => controller.materializeApprovedProposal(),
                onDone: () {
                  ref.invalidate(resumableStoryBuilderSessionsProvider);
                  Navigator.of(context).maybePop();
                },
              ),
              StoryBuilderUiPhase.questioning => _QuestionBody(
                state: state,
                textController: _textController,
                onDraftChanged: controller.updateDraft,
                onBack: state.canGoBack && !state.isBusy
                    ? () => controller.goBack()
                    : null,
                onSkip: state.isBusy ? null : () => controller.skipCurrent(),
                onContinue: state.isBusy
                    ? null
                    : () => controller.continueForward(),
                onFinish: state.canFinishEarly && !state.isBusy
                    ? () => controller.finishSession()
                    : null,
                theme: theme,
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _ThinkingBody extends StatelessWidget {
  const _ThinkingBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('story-builder-thinking'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 20),
        Text(
          'Thinking…',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The AI Story Coach is choosing the next question.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _QuestionBody extends StatelessWidget {
  const _QuestionBody({
    required this.state,
    required this.textController,
    required this.onDraftChanged,
    required this.onBack,
    required this.onSkip,
    required this.onContinue,
    required this.onFinish,
    required this.theme,
  });

  final StoryBuilderUiState state;
  final TextEditingController textController;
  final ValueChanged<String> onDraftChanged;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final VoidCallback? onContinue;
  final VoidCallback? onFinish;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final prompt = state.prompt;
    final progressLabel = state.isAiMode
        ? 'Question ${state.displayStep}'
        : 'Question ${state.displayStep} of ${state.totalQuestions}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          progressLabel,
          key: const ValueKey('story-builder-progress'),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          state.isAiMode
              ? 'AI Story Coach — you remain the author.'
              : "Let's tell your story together.",
          key: const ValueKey('story-builder-coach-label'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          prompt?.text ?? '',
          key: const ValueKey('story-builder-prompt'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: TextField(
            key: const ValueKey('story-builder-response-field'),
            controller: textController,
            onChanged: onDraftChanged,
            enabled: !state.isBusy,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: 'Write in your own words…',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            state.errorMessage!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            TextButton(
              key: const ValueKey('story-builder-back'),
              onPressed: onBack,
              child: const Text('Back'),
            ),
            const Spacer(),
            if (onFinish != null)
              TextButton(
                key: const ValueKey('story-builder-finish'),
                onPressed: onFinish,
                child: const Text('Finish'),
              ),
            TextButton(
              key: const ValueKey('story-builder-skip'),
              onPressed: onSkip,
              child: const Text('Skip'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              key: const ValueKey('story-builder-continue'),
              onPressed: onContinue,
              child: state.isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Continue'),
            ),
          ],
        ),
      ],
    );
  }
}

class _CompletedBody extends StatelessWidget {
  const _CompletedBody({
    required this.onDone,
    required this.isAiMode,
    required this.onBuildProposal,
    this.isBusy = false,
    this.errorMessage,
  });

  final VoidCallback onDone;
  final VoidCallback? onBuildProposal;
  final bool isAiMode;
  final bool isBusy;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Text(
          'Your story material is saved.',
          key: const ValueKey('story-builder-completed'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isAiMode
              ? 'You collected your own words with help from the AI Story Coach. '
                  'The coach asked questions — it did not write your story. '
                  'Later, you can shape this into a Story when you are ready.'
              : 'You collected your own words through the guided Story Builder. '
                  'No AI was required. Later, you can shape this into a Story when you are ready.',
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            key: const ValueKey('story-builder-proposal-error'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const Spacer(),
        FilledButton(
          key: const ValueKey('story-builder-build-proposal'),
          onPressed: onBuildProposal,
          child: Text(isBusy ? 'Building proposal…' : 'Build Story Proposal'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const ValueKey('story-builder-done'),
          onPressed: onDone,
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _ProposalReviewBody extends StatefulWidget {
  const _ProposalReviewBody({
    required this.proposal,
    required this.isAiAssisted,
    required this.showingOriginal,
    required this.canCompare,
    required this.canImproveWithAi,
    required this.isBusy,
    required this.errorMessage,
    required this.onImproveWithAi,
    required this.onToggleCompare,
    required this.onBack,
    required this.onSaveEdits,
    required this.onApprove,
    required this.onReject,
    required this.onBeginRevision,
    required this.onRetryMaterialize,
    required this.onDone,
  });

  final StoryProposal proposal;
  final bool isAiAssisted;
  final bool showingOriginal;
  final bool canCompare;
  final bool canImproveWithAi;
  final bool isBusy;
  final String? errorMessage;
  final VoidCallback onImproveWithAi;
  final VoidCallback onToggleCompare;
  final VoidCallback onBack;
  final Future<bool> Function({
    required String? title,
    required bool updateTitle,
    required bool clearTitle,
    required String? summary,
    required bool updateSummary,
    required bool clearSummary,
    required List<StoryProposalSectionEdit> sectionEdits,
  }) onSaveEdits;
  final Future<bool> Function() onApprove;
  final Future<bool> Function() onReject;
  final Future<bool> Function() onBeginRevision;
  final Future<bool> Function() onRetryMaterialize;
  final VoidCallback onDone;

  @override
  State<_ProposalReviewBody> createState() => _ProposalReviewBodyState();
}

class _ProposalReviewBodyState extends State<_ProposalReviewBody> {
  late TextEditingController _titleController;
  late TextEditingController _summaryController;
  late Map<String, TextEditingController> _sectionControllers;
  late List<StoryProposalSection> _editableSections;
  var _boundProposalId = '';
  var _boundUpdatedAt = '';

  @override
  void initState() {
    super.initState();
    _bindControllers(widget.proposal);
  }

  @override
  void didUpdateWidget(covariant _ProposalReviewBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    final proposal = widget.proposal;
    final identity = proposal.id.value;
    final updated = proposal.updatedAt.toIso8601String();
    if (identity != _boundProposalId || updated != _boundUpdatedAt) {
      _disposeControllers();
      _bindControllers(proposal);
    }
  }

  void _bindControllers(StoryProposal proposal) {
    _boundProposalId = proposal.id.value;
    _boundUpdatedAt = proposal.updatedAt.toIso8601String();
    _editableSections = [
      for (final section in proposal.sections)
        if (!section.wasSkipped) section,
    ];
    _titleController = TextEditingController(text: proposal.title?.value ?? '');
    _summaryController = TextEditingController(
      text: proposal.derivedSummary ?? '',
    );
    _sectionControllers = {
      for (final section in _editableSections)
        section.id.value: TextEditingController(text: section.content ?? ''),
    };
  }

  void _disposeControllers() {
    _titleController.dispose();
    _summaryController.dispose();
    for (final controller in _sectionControllers.values) {
      controller.dispose();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  bool get _isAccepted =>
      widget.proposal.lifecycle == StoryProposalLifecycleStatus.accepted;

  bool get _isRejected =>
      widget.proposal.lifecycle == StoryProposalLifecycleStatus.rejected;

  bool get _isEditable =>
      widget.proposal.lifecycle == StoryProposalLifecycleStatus.readyForReview &&
      !widget.showingOriginal;

  Future<void> _handleSave() async {
    final sectionEdits = <StoryProposalSectionEdit>[];
    for (final section in _editableSections) {
      final text = _sectionControllers[section.id.value]?.text;
      if (text == null) continue;
      final trimmed = text.trim();
      final normalized = trimmed.isEmpty ? null : trimmed;
      if (normalized != section.content) {
        sectionEdits.add(
          StoryProposalSectionEdit(
            sectionId: section.id,
            content: normalized,
          ),
        );
      }
    }

    final titleText = _titleController.text.trim();
    final previousTitle = widget.proposal.title?.value ?? '';
    final summaryText = _summaryController.text.trim();
    final previousSummary = widget.proposal.derivedSummary ?? '';

    await widget.onSaveEdits(
      title: titleText.isEmpty ? null : titleText,
      updateTitle: titleText != previousTitle,
      clearTitle: titleText.isEmpty && previousTitle.isNotEmpty,
      summary: summaryText.isEmpty ? null : summaryText,
      updateSummary: summaryText != previousSummary,
      clearSummary: summaryText.isEmpty && previousSummary.isNotEmpty,
      sectionEdits: sectionEdits,
    );
  }

  Future<void> _confirmApprove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Approve Story?'),
          content: const Text(
            'You are approving this version of your story. '
            'You can make changes before approval.',
          ),
          actions: [
            TextButton(
              key: const ValueKey('story-builder-approve-cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const ValueKey('story-builder-approve-confirm'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await widget.onApprove();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isAccepted) {
      return _ApprovedBody(
        onEdit: widget.isBusy ? null : () => widget.onBeginRevision(),
        onRetryMaterialize:
            widget.isBusy ? null : () => widget.onRetryMaterialize(),
        onDone: widget.onDone,
        isBusy: widget.isBusy,
        errorMessage: widget.errorMessage,
      );
    }

    if (_isRejected) {
      return _RejectedBody(
        onEdit: widget.isBusy ? null : () => widget.onBeginRevision(),
        onDone: widget.onDone,
        isBusy: widget.isBusy,
      );
    }

    final hasAiAssistedSections = widget.proposal.sections.any(
      (s) =>
          !s.wasSkipped &&
          s.contentOrigin == StoryProposalContentOrigin.derived &&
          s.content != null &&
          s.content!.trim().isNotEmpty,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Review Your Story',
          key: const ValueKey('story-builder-proposal-preview'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your story is built from what you shared. '
          'AI-assisted sections are clearly identified.',
          key: const ValueKey('story-builder-proposal-disclaimer'),
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
        if (widget.isAiAssisted) ...[
          const SizedBox(height: 8),
          Text(
            widget.showingOriginal
                ? 'Your original material'
                : 'AI-assisted story proposal',
            key: const ValueKey('story-builder-proposal-ai-disclosure'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (widget.errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.errorMessage!,
            key: const ValueKey('story-builder-review-error'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: [
              Text(
                'Title',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                key: const ValueKey('story-builder-review-title'),
                controller: _titleController,
                enabled: _isEditable && !widget.isBusy,
                decoration: const InputDecoration(
                  hintText: 'Add a title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Summary',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                key: const ValueKey('story-builder-review-summary'),
                controller: _summaryController,
                enabled: _isEditable && !widget.isBusy,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Add a short summary',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Your Story',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              for (final section in _editableSections) ...[
                _SectionReviewBlock(
                  section: section,
                  controller: _sectionControllers[section.id.value]!,
                  editable: _isEditable && !widget.isBusy,
                ),
                const SizedBox(height: 12),
              ],
              if (hasAiAssistedSections || widget.isAiAssisted) ...[
                const SizedBox(height: 8),
                Text(
                  'AI-assisted content',
                  key: const ValueKey('story-builder-ai-assisted-note-title'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI helped shape some wording from the experiences '
                  'you provided. It did not create new experiences or facts.',
                  key: const ValueKey('story-builder-ai-assisted-note'),
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (widget.canImproveWithAi)
          FilledButton(
            key: const ValueKey('story-builder-improve-with-ai'),
            onPressed: widget.isBusy ? null : widget.onImproveWithAi,
            child: Text(
              widget.isBusy ? 'Creating AI story…' : 'Improve with AI',
            ),
          ),
        if (widget.canImproveWithAi) const SizedBox(height: 8),
        if (widget.canCompare)
          OutlinedButton(
            key: const ValueKey('story-builder-proposal-compare'),
            onPressed: widget.onToggleCompare,
            child: Text(
              widget.showingOriginal
                  ? 'Show AI-assisted version'
                  : 'Show your original material',
            ),
          ),
        if (widget.canCompare) const SizedBox(height: 8),
        if (_isEditable)
          FilledButton.tonal(
            key: const ValueKey('story-builder-review-save'),
            onPressed: widget.isBusy ? null : _handleSave,
            child: Text(widget.isBusy ? 'Saving…' : 'Save Changes'),
          ),
        if (_isEditable) const SizedBox(height: 8),
        if (_isEditable)
          OutlinedButton(
            key: const ValueKey('story-builder-review-reject'),
            onPressed: widget.isBusy ? null : () => widget.onReject(),
            child: const Text('Reject'),
          ),
        if (_isEditable) const SizedBox(height: 8),
        if (_isEditable)
          FilledButton(
            key: const ValueKey('story-builder-review-approve'),
            onPressed: widget.isBusy ? null : _confirmApprove,
            child: const Text('Approve Story'),
          ),
        if (_isEditable) const SizedBox(height: 8),
        OutlinedButton(
          key: const ValueKey('story-builder-proposal-back'),
          onPressed: widget.onBack,
          child: const Text('Back'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const ValueKey('story-builder-proposal-done'),
          onPressed: widget.onDone,
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _SectionReviewBlock extends StatelessWidget {
  const _SectionReviewBlock({
    required this.section,
    required this.controller,
    required this.editable,
  });

  final StoryProposalSection section;
  final TextEditingController controller;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDerived =
        section.contentOrigin == StoryProposalContentOrigin.derived;
    final originLabel = isDerived
        ? (section.heroEdited ? 'AI-assisted · edited by you' : 'AI-assisted')
        : (section.heroEdited ? 'Hero-authored · edited' : 'Hero-authored');
    final originKey = isDerived
        ? 'story-builder-section-origin-ai-${section.id.value}'
        : 'story-builder-section-origin-hero-${section.id.value}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _roleLabel(section.narrativeRole),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              originLabel,
              key: ValueKey(originKey),
              style: theme.textTheme.labelMedium?.copyWith(
                color: isDerived
                    ? theme.colorScheme.tertiary
                    : theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          key: ValueKey('story-builder-review-section-${section.id.value}'),
          controller: controller,
          enabled: editable,
          maxLines: 5,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  static String _roleLabel(StoryBuilderNarrativeRole role) {
    return switch (role) {
      StoryBuilderNarrativeRole.beginning => 'Beginning',
      StoryBuilderNarrativeRole.challenge => 'Challenge',
      StoryBuilderNarrativeRole.importance => 'Importance',
      StoryBuilderNarrativeRole.struggle => 'Struggle',
      StoryBuilderNarrativeRole.stakes => 'Stakes',
      StoryBuilderNarrativeRole.turningPoint => 'Turning point',
      StoryBuilderNarrativeRole.decision => 'Decision',
      StoryBuilderNarrativeRole.action => 'Action',
      StoryBuilderNarrativeRole.outcome => 'Outcome',
      StoryBuilderNarrativeRole.reflection => 'Reflection',
      StoryBuilderNarrativeRole.message => 'Message',
    };
  }
}

class _ApprovedBody extends StatelessWidget {
  const _ApprovedBody({
    required this.onEdit,
    required this.onRetryMaterialize,
    required this.onDone,
    required this.isBusy,
    this.errorMessage,
  });

  final VoidCallback? onEdit;
  final VoidCallback? onRetryMaterialize;
  final VoidCallback onDone;
  final bool isBusy;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = errorMessage != null && errorMessage!.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          hasError ? 'Story Approved — Create Failed' : 'Story Approved',
          key: const ValueKey('story-builder-proposal-approved'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          hasError
              ? 'Your approval is still saved. You can retry creating the Story. '
                  'Creating a Story does not publish it.'
              : isBusy
                  ? 'You approved this version. Creating your Story… '
                      'Creating a Story does not publish it.'
                  : 'You approved this version of your story. '
                      'Create the Story when you are ready. '
                      'Creating a Story does not publish it.',
          key: const ValueKey('story-builder-proposal-approved-next'),
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
        if (hasError) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            key: const ValueKey('story-builder-materialize-error'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const Spacer(),
        FilledButton(
          key: const ValueKey('story-builder-materialize-retry'),
          onPressed: onRetryMaterialize,
          child: Text(
            isBusy
                ? 'Creating Story…'
                : hasError
                    ? 'Retry Create Story'
                    : 'Create Story',
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const ValueKey('story-builder-proposal-edit-after-approve'),
          onPressed: onEdit,
          child: Text(isBusy ? 'Opening editor…' : 'Edit'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          key: const ValueKey('story-builder-proposal-done'),
          onPressed: onDone,
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _StoryCreatedBody extends StatelessWidget {
  const _StoryCreatedBody({
    required this.story,
    required this.onDone,
    required this.onContinueToStory,
    required this.onEdit,
    required this.isBusy,
  });

  final Story story;
  final VoidCallback onDone;
  final VoidCallback onContinueToStory;
  final VoidCallback? onEdit;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('story-builder-story-created'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Your story has been created.',
          key: const ValueKey('story-builder-story-created-title'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          story.title.value,
          key: const ValueKey('story-builder-story-created-story-title'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Story created. Not yet published.',
          key: const ValueKey('story-builder-story-created-unpublished'),
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
        const SizedBox(height: 8),
        Text(
          'Continue to your story to Submit, Approve, and Publish when ready.',
          key: const ValueKey('story-builder-story-created-publish-hint'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const Spacer(),
        FilledButton(
          key: const ValueKey('story-builder-story-created-continue'),
          onPressed: onContinueToStory,
          child: const Text('Continue to Story'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const ValueKey('story-builder-proposal-edit-after-approve'),
          onPressed: onEdit,
          child: Text(isBusy ? 'Opening editor…' : 'Edit'),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const ValueKey('story-builder-story-created-done'),
          onPressed: onDone,
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _RejectedBody extends StatelessWidget {
  const _RejectedBody({
    required this.onEdit,
    required this.onDone,
    required this.isBusy,
  });

  final VoidCallback? onEdit;
  final VoidCallback onDone;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Story Proposal Rejected',
          key: const ValueKey('story-builder-proposal-rejected'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'This proposal was rejected and remains saved. '
          'You can edit it and approve a new version when you are ready.',
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
        const Spacer(),
        OutlinedButton(
          key: const ValueKey('story-builder-proposal-edit-after-reject'),
          onPressed: onEdit,
          child: Text(isBusy ? 'Opening editor…' : 'Edit'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          key: const ValueKey('story-builder-proposal-done'),
          onPressed: onDone,
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _AuthoringUnavailableBody extends StatelessWidget {
  const _AuthoringUnavailableBody({
    required this.message,
    required this.onRetry,
    required this.onContinueWithCurrent,
    required this.onExit,
  });

  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onContinueWithCurrent;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Text(
          "We couldn't create the AI version of your story. "
          'Your existing story proposal is still safe.',
          key: const ValueKey('story-builder-authoring-unavailable'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(message),
        const SizedBox(height: 16),
        FilledButton(
          key: const ValueKey('story-builder-authoring-retry'),
          onPressed: onRetry,
          child: const Text('Retry'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const ValueKey('story-builder-authoring-continue'),
          onPressed: onContinueWithCurrent,
          child: const Text('Continue with current proposal'),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const ValueKey('story-builder-authoring-exit'),
          onPressed: onExit,
          child: const Text('Exit'),
        ),
        const Spacer(),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Text(message),
        const SizedBox(height: 16),
        FilledButton(onPressed: onRetry, child: const Text('Try again')),
        const Spacer(),
      ],
    );
  }
}

class _CoachUnavailableBody extends StatelessWidget {
  const _CoachUnavailableBody({
    required this.message,
    required this.onRetry,
    required this.onContinueGuided,
    required this.onBack,
  });

  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onContinueGuided;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Text(
          'AI Story Coach unavailable',
          key: const ValueKey('story-builder-coach-unavailable-title'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          key: const ValueKey('story-builder-coach-unavailable-message'),
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
        const SizedBox(height: 8),
        Text(
          'Your answers so far are saved. The session stays in AI mode unless '
          'you choose Guided Builder.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const Spacer(),
        FilledButton(
          key: const ValueKey('story-builder-coach-retry'),
          onPressed: onRetry,
          child: const Text('Retry AI Coach'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const ValueKey('story-builder-continue-guided'),
          onPressed: onContinueGuided,
          child: const Text('Continue with Guided Builder'),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const ValueKey('story-builder-coach-back'),
          onPressed: onBack,
          child: const Text('Save and exit'),
        ),
      ],
    );
  }
}

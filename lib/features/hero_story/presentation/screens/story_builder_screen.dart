import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_mode.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_narrative_role.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal_section.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/resumable_story_builder_sessions_provider.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/story_builder_controller.dart';

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
              StoryBuilderUiPhase.proposalPreview => _ProposalPreviewBody(
                proposal: state.proposal!,
                onBack: () => controller.leaveProposalPreview(),
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

class _ProposalPreviewBody extends StatelessWidget {
  const _ProposalPreviewBody({
    required this.proposal,
    required this.onBack,
    required this.onDone,
  });

  final StoryProposal proposal;
  final VoidCallback onBack;
  final VoidCallback onDone;

  /// Presentation sections: meaningful content only (SB.10 shaped review).
  List<StoryProposalSection> get _presentedSections {
    return [
      for (final section in proposal.sections)
        if (!section.wasSkipped &&
            section.content != null &&
            section.content!.trim().isNotEmpty)
          section,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presented = _presentedSections;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Review your story',
          key: const ValueKey('story-builder-proposal-preview'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Shaping organizes your story using the material you provided. '
          'It does not add facts to your story.',
          key: const ValueKey('story-builder-proposal-disclaimer'),
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: presented.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final section = presented[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _roleLabel(section.narrativeRole),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    section.content!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const ValueKey('story-builder-proposal-back'),
          onPressed: onBack,
          child: const Text('Back'),
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

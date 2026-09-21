import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/presentation/providers/story_builder_controller.dart';

/// Guided (deterministic) Story Builder — SB.3.
///
/// Collects Hero-authored responses. No AI, credits, or network required.
class StoryBuilderScreen extends ConsumerStatefulWidget {
  const StoryBuilderScreen({super.key, this.resumeSessionId});

  /// When null, starts a new guided session on first frame.
  final String? resumeSessionId;

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
      if (widget.resumeSessionId != null) {
        // Resume by opaque id string is deferred; always start new for MVP entry.
      }
      await controller.startNewSession();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Build My Story'),
        actions: [
          if (state.phase == StoryBuilderUiPhase.questioning)
            TextButton(
              key: const ValueKey('story-builder-pause'),
              onPressed: state.isBusy
                  ? null
                  : () async {
                      await controller.pause();
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
            StoryBuilderUiPhase.error => _ErrorBody(
              message: state.errorMessage ?? 'Something went wrong.',
              onRetry: () => controller.startNewSession(),
            ),
            StoryBuilderUiPhase.completed => _CompletedBody(
              onDone: () => Navigator.of(context).maybePop(),
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
              theme: theme,
            ),
          },
        ),
      ),
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
    required this.theme,
  });

  final StoryBuilderUiState state;
  final TextEditingController textController;
  final ValueChanged<String> onDraftChanged;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final VoidCallback? onContinue;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final prompt = state.prompt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Question ${state.displayStep} of ${state.totalQuestions}',
          key: const ValueKey('story-builder-progress'),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Let's tell your story together.",
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
  const _CompletedBody({required this.onDone});

  final VoidCallback onDone;

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
          'You collected your own words through the guided Story Builder. '
          'No AI was required. Later, you can shape this into a Story when you are ready.',
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
        const Spacer(),
        FilledButton(
          key: const ValueKey('story-builder-done'),
          onPressed: onDone,
          child: const Text('Done'),
        ),
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

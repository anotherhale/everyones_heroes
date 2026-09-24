import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/application/recording/device_recording_port.dart';
import 'package:everyonesheroes/features/hero_story/application/recording/recording_session_state.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/owned_story_providers.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/tell_your_story_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/hero_story_screen.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/my_stories_screen.dart';

/// HS.9 Tell Your Story vertical slice entry screen.
class TellYourStoryScreen extends ConsumerStatefulWidget {
  const TellYourStoryScreen({super.key});

  @override
  ConsumerState<TellYourStoryScreen> createState() =>
      _TellYourStoryScreenState();
}

class _TellYourStoryScreenState extends ConsumerState<TellYourStoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(tellYourStoryControllerProvider.notifier).startFlow();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tellYourStoryControllerProvider);
    final controller = ref.read(tellYourStoryControllerProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tell Your Story'),
        key: const ValueKey('tell-your-story-app-bar'),
      ),
      body: SafeArea(
        child: state.isBusy && state.phase == RecordingSessionPhase.idle
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                children: [
                  _StepBanner(step: state.step),
                  const SizedBox(height: 16),
                  if (state.errorMessage != null) ...[
                    _ErrorBanner(message: state.errorMessage!),
                    const SizedBox(height: 16),
                  ],
                  switch (state.step) {
                    TellYourStoryStep.prepare => _PrepareStep(
                      state: state,
                      onRequestPermission: controller.requestPermissions,
                      onContinue: controller.continueToRecord,
                    ),
                    TellYourStoryStep.record => _RecordStep(
                      state: state,
                      onStart: controller.startRecording,
                      onPause: controller.pauseRecording,
                      onResume: controller.resumeRecording,
                      onStop: controller.stopRecording,
                    ),
                    TellYourStoryStep.review => _ReviewStep(
                      state: state,
                      onPlay: controller.playReview,
                      onStopPlay: controller.stopReviewPlayback,
                      onTitleChanged: controller.updateTitle,
                      onAccept: controller.acceptRecording,
                      onRetake: controller.retake,
                      onDiscard: controller.discard,
                    ),
                    TellYourStoryStep.consent => _ConsentStep(
                      state: state,
                      onProcessingChanged: controller.setGrantProcessing,
                      onAiChanged: controller.setGrantAiTransformation,
                      onContinue: controller.submitConsent,
                      onSkip: controller.skipConsentForNow,
                    ),
                    TellYourStoryStep.completed => _CompletedStep(
                      storyId: state.capturedStoryId?.value,
                      theme: theme,
                      onViewStory: state.capturedStoryId == null
                          ? null
                          : () {
                              ref.invalidate(ownedStoriesProvider);
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => HeroStoryScreen(
                                    storyId: state.capturedStoryId!.value,
                                  ),
                                ),
                              );
                            },
                      onMyStories: () {
                        ref.invalidate(ownedStoriesProvider);
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => const MyStoriesScreen(),
                          ),
                        );
                      },
                      onDone: () {
                        ref.invalidate(ownedStoriesProvider);
                        Navigator.of(context).maybePop();
                      },
                    ),
                  },
                ],
              ),
      ),
    );
  }
}

class _StepBanner extends StatelessWidget {
  const _StepBanner({required this.step});

  final TellYourStoryStep step;

  @override
  Widget build(BuildContext context) {
    final label = switch (step) {
      TellYourStoryStep.prepare => 'Prepare',
      TellYourStoryStep.record => 'Recording',
      TellYourStoryStep.review => 'Review',
      TellYourStoryStep.consent => 'Consent',
      TellYourStoryStep.completed => 'Saved',
    };
    return Text(
      label,
      key: ValueKey('tell-your-story-step-$label'),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          key: const ValueKey('tell-your-story-error'),
          style: TextStyle(color: scheme.onErrorContainer),
        ),
      ),
    );
  }
}

class _PrepareStep extends StatelessWidget {
  const _PrepareStep({
    required this.state,
    required this.onRequestPermission,
    required this.onContinue,
  });

  final TellYourStoryUiState state;
  final VoidCallback onRequestPermission;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share a lived experience',
          key: const ValueKey('prepare-title'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Find a quiet place, hold your phone steady, and speak for a few '
          'minutes about a challenge you faced and what it meant to you.',
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
        const SizedBox(height: 16),
        Text(
          'Your recording creates a private draft Story owned by you. '
          'Recording is not the same as publishing. You will choose processing '
          'and AI permissions separately after you accept the recording.',
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 24),
        Text(
          'Microphone: ${_permissionLabel(state.permissionStatus)}',
          key: const ValueKey('mic-permission-status'),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        if (state.permissionStatus != DevicePermissionStatus.granted)
          FilledButton(
            key: const ValueKey('request-mic-permission-button'),
            onPressed: state.isBusy ? null : onRequestPermission,
            child: const Text('Allow microphone'),
          )
        else
          FilledButton(
            key: const ValueKey('continue-to-record-button'),
            onPressed: state.isBusy ? null : onContinue,
            child: const Text('Continue to record'),
          ),
        if (state.permissionStatus ==
                DevicePermissionStatus.permanentlyDenied ||
            state.permissionStatus == DevicePermissionStatus.unavailable) ...[
          const SizedBox(height: 12),
          Text(
            'Open your device settings to enable microphone access, then return '
            'and try again.',
            key: const ValueKey('permission-settings-guidance'),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }

  String _permissionLabel(DevicePermissionStatus status) {
    return switch (status) {
      DevicePermissionStatus.notDetermined => 'Not requested',
      DevicePermissionStatus.granted => 'Granted',
      DevicePermissionStatus.denied => 'Denied',
      DevicePermissionStatus.permanentlyDenied => 'Permanently denied',
      DevicePermissionStatus.unavailable => 'Unavailable',
    };
  }
}

class _RecordStep extends StatelessWidget {
  const _RecordStep({
    required this.state,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  final TellYourStoryUiState state;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRecording = state.phase == RecordingSessionPhase.recording;
    final isPaused = state.phase == RecordingSessionPhase.paused;
    final canStart =
        state.phase == RecordingSessionPhase.ready ||
        state.phase == RecordingSessionPhase.consenting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatDuration(state.elapsed),
          key: const ValueKey('recording-timer'),
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isRecording
              ? 'Recording…'
              : isPaused
              ? 'Paused'
              : 'Ready to record',
          key: const ValueKey('recording-status-label'),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (canStart)
              FilledButton(
                key: const ValueKey('start-recording-button'),
                onPressed: state.isBusy ? null : onStart,
                child: const Text('Start'),
              ),
            if (isRecording)
              OutlinedButton(
                key: const ValueKey('pause-recording-button'),
                onPressed: state.isBusy ? null : onPause,
                child: const Text('Pause'),
              ),
            if (isPaused)
              FilledButton(
                key: const ValueKey('resume-recording-button'),
                onPressed: state.isBusy ? null : onResume,
                child: const Text('Resume'),
              ),
            if (isRecording || isPaused)
              FilledButton.tonal(
                key: const ValueKey('stop-recording-button'),
                onPressed: state.isBusy ? null : onStop,
                child: const Text('Stop'),
              ),
          ],
        ),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.state,
    required this.onPlay,
    required this.onStopPlay,
    required this.onTitleChanged,
    required this.onAccept,
    required this.onRetake,
    required this.onDiscard,
  });

  final TellYourStoryUiState state;
  final VoidCallback onPlay;
  final VoidCallback onStopPlay;
  final ValueChanged<String> onTitleChanged;
  final VoidCallback onAccept;
  final VoidCallback onRetake;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review your recording',
          key: const ValueKey('review-title'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Duration ${_formatDuration(state.elapsed)}',
          key: const ValueKey('review-duration'),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('review-title-field'),
          decoration: const InputDecoration(
            labelText: 'Title (optional)',
            border: OutlineInputBorder(),
          ),
          onChanged: onTitleChanged,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            FilledButton.tonalIcon(
              key: const ValueKey('review-play-button'),
              onPressed: state.isPlayingReview ? onStopPlay : onPlay,
              icon: Icon(state.isPlayingReview ? Icons.stop : Icons.play_arrow),
              label: Text(state.isPlayingReview ? 'Stop' : 'Play'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton(
          key: const ValueKey('accept-recording-button'),
          onPressed: state.isBusy ? null : onAccept,
          child: state.isBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Accept recording'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          key: const ValueKey('retake-recording-button'),
          onPressed: state.isBusy ? null : onRetake,
          child: const Text('Retake'),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const ValueKey('discard-recording-button'),
          onPressed: state.isBusy ? null : onDiscard,
          child: const Text('Discard'),
        ),
      ],
    );
  }
}

class _ConsentStep extends StatelessWidget {
  const _ConsentStep({
    required this.state,
    required this.onProcessingChanged,
    required this.onAiChanged,
    required this.onContinue,
    required this.onSkip,
  });

  final TellYourStoryUiState state;
  final ValueChanged<bool> onProcessingChanged;
  final ValueChanged<bool> onAiChanged;
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Consent for next steps',
          key: const ValueKey('consent-title'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your recording is already saved as a private draft. These permissions '
          'are independent — granting one does not grant the others. Publication '
          'consent is asked later if you choose to publish.',
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          key: const ValueKey('consent-processing-switch'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Allow processing'),
          subtitle: const Text(
            'Lets Everyone’s Heroes prepare your story for review (not publish).',
          ),
          value: state.grantProcessing,
          onChanged: onProcessingChanged,
        ),
        SwitchListTile(
          key: const ValueKey('consent-ai-switch'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Allow AI assistance'),
          subtitle: const Text(
            'Optional. AI may help with transcription or drafts; it does not own your story.',
          ),
          value: state.grantAiTransformation,
          onChanged: onAiChanged,
        ),
        const SizedBox(height: 20),
        FilledButton(
          key: const ValueKey('save-consent-button'),
          onPressed: state.isBusy ? null : onContinue,
          child: const Text('Save consent choices'),
        ),
        TextButton(
          key: const ValueKey('skip-consent-button'),
          onPressed: state.isBusy ? null : onSkip,
          child: const Text('Skip for now'),
        ),
      ],
    );
  }
}

class _CompletedStep extends StatelessWidget {
  const _CompletedStep({
    required this.storyId,
    required this.theme,
    required this.onDone,
    this.onViewStory,
    this.onMyStories,
  });

  final String? storyId;
  final ThemeData theme;
  final VoidCallback onDone;
  final VoidCallback? onViewStory;
  final VoidCallback? onMyStories;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Story Saved',
          key: const ValueKey('capture-completed-title'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your story has been safely saved. It remains private and is not '
          'discoverable.',
          key: const ValueKey('capture-completed-body'),
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
        ),
        if (storyId != null) ...[
          const SizedBox(height: 12),
          Text(
            'Story id: $storyId',
            key: const ValueKey('captured-story-id'),
            style: theme.textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 24),
        if (onViewStory != null) ...[
          FilledButton.icon(
            key: const ValueKey('capture-view-story-button'),
            onPressed: onViewStory,
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('Hero Story'),
          ),
          const SizedBox(height: 12),
        ],
        if (onMyStories != null) ...[
          OutlinedButton.icon(
            key: const ValueKey('capture-my-stories-button'),
            onPressed: onMyStories,
            icon: const Icon(Icons.library_books_outlined),
            label: const Text('My Stories'),
          ),
          const SizedBox(height: 12),
        ],
        TextButton(
          key: const ValueKey('capture-done-button'),
          onPressed: onDone,
          child: const Text('Done'),
        ),
      ],
    );
  }
}

String _formatDuration(Duration value) {
  final totalSeconds = value.inSeconds;
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

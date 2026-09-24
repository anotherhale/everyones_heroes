import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/presentation/models/captured_story_reading_view_data.dart';
import 'package:everyonesheroes/features/hero_story/presentation/models/hero_story_view_data.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_story_playback_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_story_provider.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_story_understanding_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/owned_story_detail_screen.dart';

/// Hero-owned presentation of a saved Story.
///
/// The canonical Story is unchanged. This screen plays the original recording
/// and optionally surfaces a grounded captured-story reading (HS.12.3).
class HeroStoryScreen extends ConsumerWidget {
  const HeroStoryScreen({required this.storyId, super.key});

  final String storyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final storyAsync = ref.watch(heroStoryProvider(storyId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hero Story'),
        key: const ValueKey('hero-story-app-bar'),
      ),
      body: SafeArea(
        child: storyAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              key: ValueKey('hero-story-loading'),
            ),
          ),
          error: (error, _) => _HeroStoryMessage(
            message: 'Unable to open this story.',
            messageKey: const ValueKey('hero-story-load-error'),
            onRetry: () => ref.invalidate(heroStoryProvider(storyId)),
          ),
          data: (story) =>
              _HeroStoryBody(storyId: storyId, story: story, theme: theme),
        ),
      ),
    );
  }
}

class _HeroStoryBody extends ConsumerWidget {
  const _HeroStoryBody({
    required this.storyId,
    required this.story,
    required this.theme,
  });

  final String storyId;
  final HeroStoryViewData story;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(heroStoryPlaybackProvider(storyId));
    final playbackController = ref.read(
      heroStoryPlaybackProvider(storyId).notifier,
    );
    final understanding = ref.watch(heroStoryUnderstandingProvider(storyId));
    final understandingController = ref.read(
      heroStoryUnderstandingProvider(storyId).notifier,
    );
    final recordingId = story.originalRecordingId;

    return ListView(
      key: const ValueKey('hero-story-screen'),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      children: [
        Text(
          'HERO STORY',
          key: const ValueKey('hero-story-kicker'),
          style: theme.textTheme.labelLarge?.copyWith(
            letterSpacing: 1.4,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 28),
        Center(
          child: CircleAvatar(
            key: const ValueKey('hero-story-monogram'),
            radius: 48,
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            child: Text(
              story.monogram,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          story.heroName,
          key: const ValueKey('hero-story-name'),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 20),
        Text(
          story.title,
          key: const ValueKey('hero-story-title'),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Original recording',
          key: const ValueKey('hero-story-original-label'),
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        if (recordingId == null)
          Text(
            'No original recording is available.',
            key: const ValueKey('hero-story-no-recording'),
            style: theme.textTheme.bodyLarge,
          )
        else ...[
          if (playback.errorMessage != null) ...[
            Text(
              playback.errorMessage!,
              key: const ValueKey('hero-story-playback-error'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton.icon(
            key: const ValueKey('hero-story-play-button'),
            onPressed: playback.isBusy
                ? null
                : () async {
                    if (playback.phase == HeroStoryPlaybackPhase.playing) {
                      await playbackController.pause();
                    } else {
                      await playbackController.playOriginal(
                        representationId: recordingId,
                      );
                    }
                  },
            icon: Icon(
              playback.phase == HeroStoryPlaybackPhase.playing
                  ? Icons.pause
                  : Icons.play_arrow,
            ),
            label: Text(_playLabel(playback.phase)),
          ),
          if (playback.phase == HeroStoryPlaybackPhase.playing ||
              playback.phase == HeroStoryPlaybackPhase.paused) ...[
            const SizedBox(height: 8),
            TextButton(
              key: const ValueKey('hero-story-stop-button'),
              onPressed: playback.isBusy ? null : playbackController.stop,
              child: const Text('Stop'),
            ),
          ],
        ],
        const SizedBox(height: 20),
        OutlinedButton.icon(
          key: const ValueKey('hero-story-understand-button'),
          onPressed: understanding.isProcessing
              ? null
              : () => understandingController.understand(
                    isRetry: understanding.phase ==
                        HeroStoryUnderstandingPhase.failed,
                  ),
          icon: understanding.isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome_outlined),
          label: Text(
            understanding.phase == HeroStoryUnderstandingPhase.failed
                ? 'Retry understanding'
                : understanding.phase == HeroStoryUnderstandingPhase.ready
                    ? 'Refresh understanding'
                    : 'Understand my story',
          ),
        ),
        if (understanding.isProcessing) ...[
          const SizedBox(height: 16),
          Text(
            HeroStoryUnderstandingController.processingMessage,
            key: const ValueKey('hero-story-understanding-processing'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (understanding.errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            understanding.errorMessage!,
            key: const ValueKey('hero-story-understanding-error'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your original recording is still available.',
            key: const ValueKey('hero-story-understanding-error-recording'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (understanding.reading != null) ...[
          const SizedBox(height: 28),
          _CapturedStoryReadingSection(
            reading: understanding.reading!,
            theme: theme,
          ),
        ],
        const SizedBox(height: 28),
        Text(
          'A real story from a real person',
          key: const ValueKey('hero-story-tagline'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const ValueKey('hero-story-details-button'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => OwnedStoryDetailScreen(storyId: storyId),
                ),
              );
            },
            child: const Text('Story details'),
          ),
        ),
      ],
    );
  }

  static String _playLabel(HeroStoryPlaybackPhase phase) {
    return switch (phase) {
      HeroStoryPlaybackPhase.playing => 'Pause',
      HeroStoryPlaybackPhase.paused => 'Resume',
      HeroStoryPlaybackPhase.idle ||
      HeroStoryPlaybackPhase.loading ||
      HeroStoryPlaybackPhase.completed ||
      HeroStoryPlaybackPhase.failed =>
        'Play my recording',
    };
  }
}

class _CapturedStoryReadingSection extends StatelessWidget {
  const _CapturedStoryReadingSection({
    required this.reading,
    required this.theme,
  });

  final CapturedStoryReadingViewData reading;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('hero-story-reading-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Story Understanding',
          key: const ValueKey('hero-story-reading-title'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Grounded in your transcript — not a rewrite of your story.',
          key: const ValueKey('hero-story-reading-subtitle'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        _ReadingElementTile(
          key: const ValueKey('hero-story-reading-movement'),
          label: 'Movement',
          element: reading.movement,
          theme: theme,
        ),
        _ReadingThemesTile(
          key: const ValueKey('hero-story-reading-themes'),
          themes: reading.themes,
          theme: theme,
        ),
        _ReadingElementTile(
          key: const ValueKey('hero-story-reading-challenge'),
          label: 'Challenge',
          element: reading.challenge,
          theme: theme,
        ),
        _ReadingElementTile(
          key: const ValueKey('hero-story-reading-turning-point'),
          label: 'Turning point',
          element: reading.turningPoint,
          theme: theme,
        ),
        _ReadingElementTile(
          key: const ValueKey('hero-story-reading-outcome'),
          label: 'Outcome',
          element: reading.outcome,
          theme: theme,
        ),
      ],
    );
  }
}

class _ReadingElementTile extends StatelessWidget {
  const _ReadingElementTile({
    required this.label,
    required this.element,
    required this.theme,
    super.key,
  });

  final String label;
  final GroundedElementViewData element;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(element.text, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 2),
          Text(
            'Source ${element.spanLabel}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingThemesTile extends StatelessWidget {
  const _ReadingThemesTile({
    required this.themes,
    required this.theme,
    super.key,
  });

  final List<GroundedThemeViewData> themes;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Themes',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          for (final item in themes) ...[
            Text(item.label, style: theme.textTheme.bodyLarge),
            Text(
              'Source ${item.spanLabel}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _HeroStoryMessage extends StatelessWidget {
  const _HeroStoryMessage({
    required this.message,
    required this.messageKey,
    this.onRetry,
  });

  final String message;
  final Key messageKey;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, key: messageKey, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

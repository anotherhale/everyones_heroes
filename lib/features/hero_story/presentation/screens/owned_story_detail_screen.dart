import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/story_id_request.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/owned_story_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/presentation/models/owned_story_detail_view_model.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/owned_story_playback_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/owned_story_providers.dart';
import 'package:everyonesheroes/features/hero_story/presentation/widgets/owned_story_transcription_section.dart';

/// Owner Story detail with original recording playback (HS.10).
class OwnedStoryDetailScreen extends ConsumerWidget {
  const OwnedStoryDetailScreen({
    required this.storyId,
    super.key,
  });

  final String storyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final detailAsync = ref.watch(ownedStoryDetailProvider(storyId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Story'),
        key: const ValueKey('owned-story-detail-app-bar'),
      ),
      body: SafeArea(
        child: detailAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              key: ValueKey('owned-story-detail-loading'),
            ),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Unable to load this story.',
                    key: const ValueKey('owned-story-detail-error'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(ownedStoryDetailProvider(storyId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (detail) => _OwnedStoryDetailBody(
            detail: detail,
            theme: theme,
            onArchive: () => _confirmArchive(context, ref, detail),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmArchive(
    BuildContext context,
    WidgetRef ref,
    OwnedStoryDetailViewModel detail,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Archive this story?'),
          content: const Text(
            'Archived stories leave My Stories but are not permanently deleted. '
            'Your original recording remains saved on this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const ValueKey('confirm-archive-button'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Archive'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    final result = await ref.read(archiveStoryUseCaseProvider).execute(
          StoryIdRequest(storyId: StoryId(storyId)),
        );
    if (!context.mounted) {
      return;
    }
    if (result is Failure<Story>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error)),
      );
      return;
    }
    if (result is! Success<Story>) {
      return;
    }
    ref.invalidate(ownedStoriesProvider);
    ref.invalidate(ownedStoryDetailProvider(storyId));
    Navigator.of(context).pop();
  }
}

class _OwnedStoryDetailBody extends ConsumerWidget {
  const _OwnedStoryDetailBody({
    required this.detail,
    required this.theme,
    required this.onArchive,
  });

  final OwnedStoryDetailViewModel detail;
  final ThemeData theme;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(
      ownedStoryPlaybackProvider(detail.storyId.value),
    );
    final playbackController = ref.read(
      ownedStoryPlaybackProvider(detail.storyId.value).notifier,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Text(
          detail.title,
          key: const ValueKey('owned-story-title'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Recorded',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          detail.recordedLabel,
          key: const ValueKey('owned-story-recorded'),
          style: theme.textTheme.bodyLarge,
        ),
        if (detail.durationLabel != null) ...[
          const SizedBox(height: 12),
          Text(
            'Duration',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            detail.durationLabel!,
            key: const ValueKey('owned-story-duration'),
            style: theme.textTheme.bodyLarge,
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              key: const ValueKey('owned-story-privacy-chip'),
              label: Text(detail.privacyLabel),
            ),
            Chip(
              key: const ValueKey('owned-story-lifecycle-chip'),
              label: Text(detail.lifecycleLabel),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Original Recording',
          key: const ValueKey('owned-story-original-heading'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This is your original contribution — the provenance-bearing source.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        if (detail.primaryOriginalAudioId == null)
          const Text(
            'No original recording is available.',
            key: ValueKey('owned-story-no-audio'),
          )
        else ...[
          if (playback.errorMessage != null) ...[
            Text(
              playback.errorMessage!,
              key: const ValueKey('owned-story-playback-error'),
              style: TextStyle(color: theme.colorScheme.error),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              FilledButton.icon(
                key: const ValueKey('owned-story-play-button'),
                onPressed: playback.isLoading
                    ? null
                    : () async {
                        if (playback.isPlaying) {
                          await playbackController.pause();
                        } else {
                          await playbackController.play(
                            representationId: detail.primaryOriginalAudioId!,
                          );
                        }
                      },
                icon: Icon(
                  playback.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
                label: Text(playback.isPlaying ? 'Pause' : 'Play'),
              ),
              const SizedBox(width: 12),
              TextButton(
                key: const ValueKey('owned-story-stop-button'),
                onPressed: playback.isLoading
                    ? null
                    : () => playbackController.stop(),
                child: const Text('Stop'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${playback.positionLabel} / ${playback.durationLabel}',
            key: const ValueKey('owned-story-playback-progress'),
            style: theme.textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        OwnedStoryTranscriptionSection(storyId: detail.storyId.value),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Privacy & Consent',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          [
            detail.privacyLabel,
            if (detail.isRecorded) 'Recording saved',
            if (detail.isProcessingApproved)
              'Processing consented'
            else
              'Processing not consented',
            if (detail.isAiTransformationApproved)
              'AI transformation consented'
            else
              'AI transformation not consented',
            if (detail.isPublicationApproved)
              'Publication consented'
            else
              'Not approved for publication',
          ].join('\n'),
          key: const ValueKey('owned-story-consent-summary'),
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
        const SizedBox(height: 24),
        if (detail.canArchive)
          OutlinedButton.icon(
            key: const ValueKey('owned-story-archive-button'),
            onPressed: onArchive,
            icon: const Icon(Icons.archive_outlined),
            label: const Text('Archive'),
          ),
      ],
    );
  }
}

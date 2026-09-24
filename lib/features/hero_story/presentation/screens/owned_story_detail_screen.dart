import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/publish_story_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/story_id_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/update_story_consent_request.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/owned_story_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_visibility.dart';
import 'package:everyonesheroes/features/hero_story/presentation/models/owned_story_detail_view_model.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/owned_story_playback_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/owned_story_providers.dart';
import 'package:everyonesheroes/features/hero_story/presentation/widgets/owned_story_transcription_section.dart';

/// Owner Story detail with original recording playback (HS.10)
/// and publication composition (HS.FG.1).
class OwnedStoryDetailScreen extends ConsumerStatefulWidget {
  const OwnedStoryDetailScreen({
    required this.storyId,
    super.key,
  });

  final String storyId;

  @override
  ConsumerState<OwnedStoryDetailScreen> createState() =>
      _OwnedStoryDetailScreenState();
}

class _OwnedStoryDetailScreenState
    extends ConsumerState<OwnedStoryDetailScreen> {
  bool _actionBusy = false;
  String? _actionError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detailAsync = ref.watch(ownedStoryDetailProvider(widget.storyId));

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
                    onPressed: () => ref.invalidate(
                      ownedStoryDetailProvider(widget.storyId),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (detail) => _OwnedStoryDetailBody(
            detail: detail,
            theme: theme,
            actionBusy: _actionBusy,
            actionError: _actionError,
            onClearActionError: () => setState(() => _actionError = null),
            onArchive: () => _confirmArchive(detail),
            onSubmit: () => _submit(detail),
            onApprove: () => _approve(detail),
            onPublish: () => _publish(detail),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmArchive(OwnedStoryDetailViewModel detail) async {
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
    if (confirmed != true || !mounted) {
      return;
    }

    final result = await ref.read(archiveStoryUseCaseProvider).execute(
          StoryIdRequest(storyId: StoryId(widget.storyId)),
        );
    if (!mounted) {
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
    ref.invalidate(ownedStoryDetailProvider(widget.storyId));
    Navigator.of(context).pop();
  }

  Future<void> _submit(OwnedStoryDetailViewModel detail) async {
    await _runLifecycleAction(() async {
      if (!detail.isProcessingApproved) {
        final consent = await ref
            .read(ownedUpdateStoryConsentUseCaseProvider)
            .execute(
              UpdateStoryConsentRequest(
                storyId: detail.storyId,
                grantProcessing: true,
              ),
            );
        if (consent is Failure<Story>) {
          return consent.error;
        }
        if (consent is! Success<Story>) {
          return 'Unable to grant processing consent.';
        }
      }

      final result = await ref.read(ownedSubmitStoryUseCaseProvider).execute(
            StoryIdRequest(storyId: detail.storyId),
          );
      if (result is Failure<Story>) {
        return result.error;
      }
      if (result is! Success<Story>) {
        return 'Unable to submit story.';
      }
      return null;
    });
  }

  Future<void> _approve(OwnedStoryDetailViewModel detail) async {
    await _runLifecycleAction(() async {
      final result = await ref.read(approveStoryUseCaseProvider).execute(
            StoryIdRequest(storyId: detail.storyId),
          );
      if (result is Failure<Story>) {
        return result.error;
      }
      if (result is! Success<Story>) {
        return 'Unable to approve story.';
      }
      return null;
    });
  }

  Future<void> _publish(OwnedStoryDetailViewModel detail) async {
    await _runLifecycleAction(() async {
      if (!detail.isPublicationApproved) {
        final consent = await ref
            .read(ownedUpdateStoryConsentUseCaseProvider)
            .execute(
              UpdateStoryConsentRequest(
                storyId: detail.storyId,
                grantPublication: true,
              ),
            );
        if (consent is Failure<Story>) {
          return consent.error;
        }
        if (consent is! Success<Story>) {
          return 'Unable to grant publication consent.';
        }
      }

      final needsDiscoverableVisibility =
          detail.visibility == StoryVisibility.private ||
              detail.visibility == StoryVisibility.draft ||
              detail.visibility == StoryVisibility.unlisted;

      final result = await ref.read(publishStoryUseCaseProvider).execute(
            PublishStoryRequest(
              storyId: detail.storyId,
              visibility: needsDiscoverableVisibility
                  ? StoryVisibility.public
                  : null,
            ),
          );
      if (result is Failure<Story>) {
        return result.error;
      }
      if (result is! Success<Story>) {
        return 'Unable to publish story.';
      }
      return null;
    });
  }

  /// Runs a lifecycle action; on failure preserves canonical Story state and
  /// surfaces the error for retry.
  Future<void> _runLifecycleAction(
    Future<String?> Function() action,
  ) async {
    if (_actionBusy) {
      return;
    }
    setState(() {
      _actionBusy = true;
      _actionError = null;
    });
    try {
      final error = await action();
      if (!mounted) {
        return;
      }
      if (error != null) {
        setState(() => _actionError = error);
        return;
      }
      ref.invalidate(ownedStoriesProvider);
      ref.invalidate(ownedStoryDetailProvider(widget.storyId));
    } finally {
      if (mounted) {
        setState(() => _actionBusy = false);
      }
    }
  }
}

class _OwnedStoryDetailBody extends ConsumerWidget {
  const _OwnedStoryDetailBody({
    required this.detail,
    required this.theme,
    required this.actionBusy,
    required this.actionError,
    required this.onClearActionError,
    required this.onArchive,
    required this.onSubmit,
    required this.onApprove,
    required this.onPublish,
  });

  final OwnedStoryDetailViewModel detail;
  final ThemeData theme;
  final bool actionBusy;
  final String? actionError;
  final VoidCallback onClearActionError;
  final VoidCallback onArchive;
  final VoidCallback onSubmit;
  final VoidCallback onApprove;
  final VoidCallback onPublish;

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
        _PublicationSection(
          detail: detail,
          theme: theme,
          actionBusy: actionBusy,
          actionError: actionError,
          onClearActionError: onClearActionError,
          onSubmit: onSubmit,
          onApprove: onApprove,
          onPublish: onPublish,
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
            if (detail.isVoiceRenderingApproved)
              'AI voice narration consented'
            else
              'AI voice narration not consented',
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
            onPressed: actionBusy ? null : onArchive,
            icon: const Icon(Icons.archive_outlined),
            label: const Text('Archive'),
          ),
      ],
    );
  }
}

class _PublicationSection extends StatelessWidget {
  const _PublicationSection({
    required this.detail,
    required this.theme,
    required this.actionBusy,
    required this.actionError,
    required this.onClearActionError,
    required this.onSubmit,
    required this.onApprove,
    required this.onPublish,
  });

  final OwnedStoryDetailViewModel detail;
  final ThemeData theme;
  final bool actionBusy;
  final String? actionError;
  final VoidCallback onClearActionError;
  final VoidCallback onSubmit;
  final VoidCallback onApprove;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    final isTerminal = detail.lifecycleStatus == StoryLifecycleStatus.archived ||
        detail.lifecycleStatus == StoryLifecycleStatus.removed ||
        detail.lifecycleStatus == StoryLifecycleStatus.rejected ||
        detail.lifecycleStatus == StoryLifecycleStatus.suspended;

    return Column(
      key: const ValueKey('owned-story-publication-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Publication',
          key: const ValueKey('owned-story-publication-heading'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _statusCopy(detail),
          key: const ValueKey('owned-story-publication-status'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        if (detail.hasProvisionalNarrative) ...[
          const SizedBox(height: 8),
          Text(
            'A provisional capture narrative must be replaced before '
            'approval or publication.',
            key: const ValueKey('owned-story-provisional-warning'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
              height: 1.4,
            ),
          ),
        ],
        if (actionError != null) ...[
          const SizedBox(height: 12),
          Text(
            actionError!,
            key: const ValueKey('owned-story-publication-error'),
            style: TextStyle(color: theme.colorScheme.error),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const ValueKey('owned-story-publication-dismiss-error'),
              onPressed: onClearActionError,
              child: const Text('Dismiss'),
            ),
          ),
        ],
        if (!isTerminal) ...[
          const SizedBox(height: 16),
          if (detail.canSubmit)
            FilledButton(
              key: const ValueKey('owned-story-submit-button'),
              onPressed: actionBusy ? null : onSubmit,
              child: Text(actionBusy ? 'Submitting…' : 'Submit'),
            ),
          if (detail.canApprove) ...[
            if (detail.canSubmit) const SizedBox(height: 8),
            FilledButton(
              key: const ValueKey('owned-story-approve-button'),
              onPressed: actionBusy ? null : onApprove,
              child: Text(actionBusy ? 'Approving…' : 'Approve'),
            ),
          ],
          if (detail.canPublish) ...[
            if (detail.canSubmit || detail.canApprove) const SizedBox(height: 8),
            FilledButton(
              key: const ValueKey('owned-story-publish-button'),
              onPressed: actionBusy ? null : onPublish,
              child: Text(actionBusy ? 'Publishing…' : 'Publish'),
            ),
          ],
          if (detail.lifecycleStatus == StoryLifecycleStatus.published)
            Text(
              'This story is published. Catalog discovery remains gated by '
              'Discovery eligibility (published + public/community visibility).',
              key: const ValueKey('owned-story-published-note'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
        ],
      ],
    );
  }

  static String _statusCopy(OwnedStoryDetailViewModel detail) {
    return switch (detail.lifecycleStatus) {
      StoryLifecycleStatus.draft =>
        'This story is a draft. Materialization is not publication. '
            'Submit when you are ready to begin the publication path.',
      StoryLifecycleStatus.processing =>
        'Submitted. Approve to mark this story ready for publication.',
      StoryLifecycleStatus.review =>
        'Ready for review. Approve to continue toward publication.',
      StoryLifecycleStatus.approved =>
        'Approved. Publish to make this story eligible for Discovery '
            '(with public visibility).',
      StoryLifecycleStatus.published =>
        'Published. Seekers may discover this story when Hero and Story '
            'eligibility are met.',
      StoryLifecycleStatus.archived => 'This story is archived.',
      StoryLifecycleStatus.rejected => 'This story was rejected.',
      StoryLifecycleStatus.suspended => 'This story is suspended.',
      StoryLifecycleStatus.removed => 'This story was removed.',
    };
  }
}

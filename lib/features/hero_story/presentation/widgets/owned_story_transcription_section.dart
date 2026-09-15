import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/domain/enums/story_transcription_job_status.dart';
import 'package:everyonesheroes/features/hero_story/presentation/models/owned_story_transcription_view_model.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/owned_story_transcription_controller.dart';

/// Owner Story Detail section for Start Transcription / review (HS.11).
class OwnedStoryTranscriptionSection extends ConsumerWidget {
  const OwnedStoryTranscriptionSection({
    required this.storyId,
    super.key,
  });

  final String storyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ui = ref.watch(ownedStoryTranscriptionProvider(storyId));
    final controller =
        ref.read(ownedStoryTranscriptionProvider(storyId).notifier);

    if (ui.isLoading && ui.model == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(
          key: ValueKey('owned-story-transcription-loading'),
        ),
      );
    }

    if (ui.model == null) {
      return Text(
        ui.errorMessage ?? 'Unable to load transcription status.',
        key: const ValueKey('owned-story-transcription-error'),
        style: TextStyle(color: theme.colorScheme.error),
      );
    }

    return _TranscriptionBody(
      storyId: storyId,
      model: ui.model!,
      theme: theme,
      busy: ui.isBusy,
      controller: controller,
    );
  }
}

class _TranscriptionBody extends ConsumerStatefulWidget {
  const _TranscriptionBody({
    required this.storyId,
    required this.model,
    required this.theme,
    required this.busy,
    required this.controller,
  });

  final String storyId;
  final OwnedStoryTranscriptionViewModel model;
  final ThemeData theme;
  final bool busy;
  final OwnedStoryTranscriptionController controller;

  @override
  ConsumerState<_TranscriptionBody> createState() => _TranscriptionBodyState();
}

class _TranscriptionBodyState extends ConsumerState<_TranscriptionBody> {
  late final TextEditingController _editController;
  var _editing = false;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(
      text: widget.model.transcriptText ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _TranscriptionBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing &&
        oldWidget.model.transcriptText != widget.model.transcriptText) {
      _editController.text = widget.model.transcriptText ?? '';
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<String?> Function() action) async {
    if (widget.busy) {
      return;
    }
    final error = await action();
    if (!mounted) {
      return;
    }
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final theme = widget.theme;
    final busy = widget.busy;
    final controller = widget.controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Transcript',
          key: const ValueKey('owned-story-transcription-heading'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'AI may help tell the story. It does not own the story. '
          'Your original recording stays the provenance source.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          model.statusLabel,
          key: const ValueKey('owned-story-transcription-status'),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (!model.hasAiProcessingConsent) ...[
          const SizedBox(height: 12),
          Text(
            'Processing and AI transformation consent are required before '
            'transcription can start.',
            key: const ValueKey('owned-story-transcription-consent-needed'),
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const ValueKey('owned-story-grant-ai-consent-button'),
            onPressed:
                busy ? null : () => _run(controller.grantAiProcessingConsent),
            child: const Text('Allow AI processing'),
          ),
        ],
        if (model.canStart) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('owned-story-start-transcription-button'),
            onPressed: busy
                ? null
                : () => _run(() => controller.startTranscription()),
            icon: const Icon(Icons.graphic_eq),
            label: const Text('Start Transcription'),
          ),
        ],
        if (model.showProcessing) ...[
          const SizedBox(height: 16),
          const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text(
                'Transcribing your original recording…',
                key: ValueKey('owned-story-transcription-processing'),
              ),
            ],
          ),
        ],
        if (model.status == StoryTranscriptionJobStatus.failed) ...[
          const SizedBox(height: 12),
          Text(
            model.errorMessage ?? 'Transcription failed.',
            key: const ValueKey('owned-story-transcription-failure'),
            style: TextStyle(color: theme.colorScheme.error, height: 1.4),
          ),
          if (model.canRetry) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('owned-story-retry-transcription-button'),
              onPressed: busy
                  ? null
                  : () => _run(
                        () => controller.startTranscription(isRetry: true),
                      ),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Transcription'),
            ),
          ],
        ],
        if (model.showTranscript) ...[
          const SizedBox(height: 16),
          Text(
            model.transcriptIsApproved
                ? 'Approved transcript'
                : 'AI-derived transcript (not yet approved)',
            key: const ValueKey('owned-story-transcript-label'),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          if (_editing)
            TextField(
              key: const ValueKey('owned-story-transcript-editor'),
              controller: _editController,
              maxLines: 8,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
                labelText: 'Edit transcript',
              ),
            )
          else
            Container(
              key: const ValueKey('owned-story-transcript-text'),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                model.transcriptText ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!model.transcriptIsApproved)
                OutlinedButton(
                  key: const ValueKey('owned-story-edit-transcript-button'),
                  onPressed: busy
                      ? null
                      : () async {
                          if (_editing) {
                            await _run(
                              () => controller.saveTranscriptEdit(
                                _editController.text,
                              ),
                            );
                            if (mounted) {
                              setState(() => _editing = false);
                            }
                          } else {
                            setState(() => _editing = true);
                          }
                        },
                  child: Text(_editing ? 'Save edits' : 'Edit transcript'),
                ),
              if (_editing)
                TextButton(
                  key: const ValueKey('owned-story-cancel-edit-transcript'),
                  onPressed: busy
                      ? null
                      : () {
                          setState(() {
                            _editing = false;
                            _editController.text = model.transcriptText ?? '';
                          });
                        },
                  child: const Text('Cancel'),
                ),
              if (!model.transcriptIsApproved)
                FilledButton(
                  key: const ValueKey('owned-story-approve-transcript-button'),
                  onPressed: busy
                      ? null
                      : () => _run(controller.approveTranscript),
                  child: const Text('Approve transcript'),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

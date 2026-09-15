import 'package:everyonesheroes/features/hero_story/domain/enums/story_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_transcription_job_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_visibility.dart';

/// Human-friendly owner Story labels (HS.10 / HS.11).
final class OwnedStoryLabels {
  const OwnedStoryLabels._();

  static String displayTitle(String rawTitle, {required DateTime createdAt}) {
    final trimmed = rawTitle.trim();
    if (trimmed.isEmpty || trimmed == 'Untitled Story') {
      return 'Story — ${formatDate(createdAt)}';
    }
    return trimmed;
  }

  static String lifecycleLabel(StoryLifecycleStatus status) {
    return switch (status) {
      StoryLifecycleStatus.draft => 'Draft',
      StoryLifecycleStatus.processing => 'Processing',
      StoryLifecycleStatus.review => 'Ready for Review',
      StoryLifecycleStatus.approved => 'Approved',
      StoryLifecycleStatus.published => 'Published',
      StoryLifecycleStatus.archived => 'Archived',
      StoryLifecycleStatus.rejected => 'Rejected',
      StoryLifecycleStatus.suspended => 'Suspended',
      StoryLifecycleStatus.removed => 'Removed',
    };
  }

  static String privacyLabel(StoryVisibility visibility) {
    return switch (visibility) {
      StoryVisibility.private => 'Private',
      StoryVisibility.draft => 'Draft visibility',
      StoryVisibility.unlisted => 'Unlisted',
      StoryVisibility.community => 'Community',
      StoryVisibility.public => 'Public',
    };
  }

  static String transcriptionStatusLabel(StoryTranscriptionJobStatus status) {
    return switch (status) {
      StoryTranscriptionJobStatus.notStarted => 'Not started',
      StoryTranscriptionJobStatus.inProgress => 'Transcribing…',
      StoryTranscriptionJobStatus.completed => 'Transcript ready',
      StoryTranscriptionJobStatus.failed => 'Transcription failed',
    };
  }

  static String formatDate(DateTime value) {
    const months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final local = value.toLocal();
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }

  static String formatDuration(Duration value) {
    final totalSeconds = value.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

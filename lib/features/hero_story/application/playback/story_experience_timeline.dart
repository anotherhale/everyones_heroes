import 'package:everyonesheroes/features/hero_story/application/playback/story_experience_demo_stem.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_step_type.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_plan.dart';

/// A single cue on the experience presentation timeline.
///
/// [at] is relative to the original recording's timeline (not wall clock).
/// Intentional silence pauses recording playback without rewriting audio.
final class StoryExperienceTimelineCue {
  const StoryExperienceTimelineCue({
    required this.at,
    required this.purpose,
    this.stem,
    this.silence = Duration.zero,
  });

  /// Position on the original recording where this cue applies.
  final Duration at;

  final StoryExperiencePresentationPurpose purpose;

  /// Demo stem to start, or null for silence / no music change.
  final StoryExperienceDemoStem? stem;

  /// Presentation-only gap. Recording is paused; bytes are not modified.
  final Duration silence;

  bool get hasSilence => silence > Duration.zero;
}

/// Ordered presentation timeline derived from a persisted plan.
final class StoryExperienceTimeline {
  const StoryExperienceTimeline({
    required this.recordingDuration,
    required this.cues,
  });

  final Duration recordingDuration;
  final List<StoryExperienceTimelineCue> cues;
}

/// Builds a deterministic presentation timeline from a persisted plan.
///
/// Pure function of [plan] + [recordingDuration] (+ optional transcript length).
/// Does not call AI, mutate the Story, or regenerate the plan.
///
/// Timing strategy (conservative):
/// - Key-moment character offsets map proportionally onto [recordingDuration].
/// - Recording timestamps on spans win when both start and end ms are present.
/// - Sequence order of `keyMoment` steps drives presentation purposes.
/// - Intentional silence is inserted before the turning-point moment.
final class StoryExperienceTimelineBuilder {
  const StoryExperienceTimelineBuilder();

  static const Duration minSilence = Duration(milliseconds: 600);
  static const Duration maxSilence = Duration(milliseconds: 2000);
  static const Duration defaultSilence = Duration(milliseconds: 1200);

  StoryExperienceTimeline build({
    required StoryExperiencePlan plan,
    required Duration recordingDuration,
    int? transcriptLength,
  }) {
    if (recordingDuration <= Duration.zero) {
      throw ArgumentError('recordingDuration must be positive.');
    }

    final momentsById = {
      for (final moment in plan.keyMoments) moment.id: moment,
    };

    final keyMomentSteps = plan.sequence
        .where((s) => s.type == StoryExperienceStepType.keyMoment)
        .toList();

    final inferredTranscriptLength = transcriptLength ??
        plan.keyMoments
            .map((m) => m.sourceSpan.endOffset ?? 0)
            .fold<int>(0, (a, b) => a > b ? a : b);

    final length = inferredTranscriptLength <= 0 ? 1 : inferredTranscriptLength;

    Duration positionForMoment(String? momentId) {
      if (momentId == null) {
        return Duration.zero;
      }
      final moment = momentsById[momentId];
      if (moment == null) {
        throw ArgumentError('Unknown key moment id "$momentId".');
      }
      final startMs = moment.sourceSpan.startTimestampMs;
      final endMs = moment.sourceSpan.endTimestampMs;
      if (startMs != null && endMs != null && endMs >= startMs) {
        final ms = startMs.clamp(0, recordingDuration.inMilliseconds);
        return Duration(milliseconds: ms);
      }
      final start = moment.sourceSpan.startOffset ?? 0;
      final ratio = (start / length).clamp(0.0, 1.0);
      return Duration(
        milliseconds: (recordingDuration.inMilliseconds * ratio).round(),
      );
    }

    final cues = <StoryExperienceTimelineCue>[];

    // Quiet opening at the start of the original recording.
    cues.add(
      StoryExperienceTimelineCue(
        at: Duration.zero,
        purpose: StoryExperiencePresentationPurpose.opening,
        stem: stemForPresentationPurpose(
          StoryExperiencePresentationPurpose.opening,
        ),
      ),
    );

    for (var i = 0; i < keyMomentSteps.length; i++) {
      final step = keyMomentSteps[i];
      final purpose = _purposeForKeyMomentIndex(i, keyMomentSteps.length);
      final at = positionForMoment(step.referenceId);
      final stem = stemForPresentationPurpose(purpose);
      final silence = purpose == StoryExperiencePresentationPurpose.turningPoint ||
              purpose == StoryExperiencePresentationPurpose.uncertainty
          ? defaultSilence
          : Duration.zero;

      cues.add(
        StoryExperienceTimelineCue(
          at: at,
          purpose: purpose,
          stem: stem,
          silence: silence,
        ),
      );
    }

    // Closing resolve near the end of the recording.
    final closingAt = Duration(
      milliseconds: (recordingDuration.inMilliseconds * 9) ~/ 10,
    );
    if (cues.every((c) => c.at < closingAt) ||
        cues.last.purpose != StoryExperiencePresentationPurpose.closing) {
      cues.add(
        StoryExperienceTimelineCue(
          at: closingAt,
          purpose: StoryExperiencePresentationPurpose.closing,
          stem: stemForPresentationPurpose(
            StoryExperiencePresentationPurpose.closing,
          ),
        ),
      );
    }

    cues.sort((a, b) => a.at.compareTo(b.at));
    return StoryExperienceTimeline(
      recordingDuration: recordingDuration,
      cues: List.unmodifiable(cues),
    );
  }

  /// Maps ordered key-moment steps onto the demo presentation arc.
  static StoryExperiencePresentationPurpose _purposeForKeyMomentIndex(
    int index,
    int total,
  ) {
    if (total <= 0) {
      return StoryExperiencePresentationPurpose.challenge;
    }
    if (total == 1) {
      return StoryExperiencePresentationPurpose.turningPoint;
    }
    if (total == 2) {
      return index == 0
          ? StoryExperiencePresentationPurpose.challenge
          : StoryExperiencePresentationPurpose.turningPoint;
    }
    // 3+ moments → difficulty → uncertainty/silence → decision → resolution…
    if (index == 0) {
      return StoryExperiencePresentationPurpose.challenge;
    }
    if (index == 1) {
      return StoryExperiencePresentationPurpose.uncertainty;
    }
    if (index == 2) {
      return StoryExperiencePresentationPurpose.decision;
    }
    if (index == total - 1) {
      return StoryExperiencePresentationPurpose.resolution;
    }
    return StoryExperiencePresentationPurpose.decision;
  }
}

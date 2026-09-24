import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_arc.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_intention.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_step_type.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_experience_planner_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/captured_story_reading.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_plan.dart';

/// Deterministic in-memory Story Experience Plan adapter (no network / no AI).
///
/// Builds grounded key-moment spans that always lie inside the supplied
/// transcript text.
final class InMemoryStoryExperiencePlannerAdapter
    implements StoryExperiencePlannerPort {
  InMemoryStoryExperiencePlannerAdapter({
    this.forcedFailureMessage,
  });

  /// When set, every call fails with this message.
  final String? forcedFailureMessage;

  @override
  Future<StoryExperiencePlanDraft> generate({
    required Story story,
    required CapturedStoryReading reading,
    required String transcriptText,
  }) async {
    if (forcedFailureMessage != null) {
      throw StoryExperiencePlannerException(forcedFailureMessage!);
    }

    final text = transcriptText;
    if (text.trim().isEmpty) {
      throw const StoryExperiencePlannerException(
        'Transcript text cannot be empty for Story Experience Plan.',
      );
    }

    final length = text.length;
    int clampEnd(int end) => end > length ? length : end;

    final third = (length / 3).ceil().clamp(1, length);
    final m1End = clampEnd(third);
    final m2End = clampEnd(third * 2);
    final m3End = length;

    String slice(int start, int end) {
      final s = start.clamp(0, length);
      final e = end.clamp(s, length);
      final raw = text.substring(s, e).trim();
      if (raw.isNotEmpty) {
        return raw.length > 160 ? '${raw.substring(0, 160)}…' : raw;
      }
      return text.trim().length > 120
          ? '${text.trim().substring(0, 120)}…'
          : text.trim();
    }

    final moments = <StoryExperiencePlanDraftMoment>[
      StoryExperiencePlanDraftMoment(
        id: 'km-1',
        description: slice(0, m1End),
        startOffset: 0,
        endOffset: m1End == 0 ? length : m1End,
      ),
      StoryExperiencePlanDraftMoment(
        id: 'km-2',
        description: slice(m1End, m2End),
        startOffset: m1End >= length ? 0 : m1End,
        endOffset: m2End == 0 ? length : m2End,
      ),
      StoryExperiencePlanDraftMoment(
        id: 'km-3',
        description: slice(m2End, m3End),
        startOffset: m2End >= length ? 0 : m2End,
        endOffset: m3End == 0 ? length : m3End,
      ),
    ];

    return StoryExperiencePlanDraft(
      intention: _intentionFor(text),
      coreMessage:
          'This story carries a grounded message drawn from the Hero\'s words: '
          '${reading.movement.text}',
      emotionalArc: _arcFor(text, reading),
      keyMoments: moments,
      musicDirection: const StoryExperiencePlanDraftMusicDirection(
        mood: 'hopeful',
        energy: 'steady',
        style: 'acoustic reflective',
        rationale:
            'Guidance follows the captured reading\'s movement from challenge '
            'toward outcome without generating audio.',
      ),
      reflectionPrompt:
          'What part of this story feels most true to your own experience?',
      sequence: [
        const StoryExperiencePlanDraftStep(type: StoryExperienceStepType.story),
        StoryExperiencePlanDraftStep(
          type: StoryExperienceStepType.keyMoment,
          referenceId: moments[0].id,
        ),
        StoryExperiencePlanDraftStep(
          type: StoryExperienceStepType.keyMoment,
          referenceId: moments[1].id,
        ),
        StoryExperiencePlanDraftStep(
          type: StoryExperienceStepType.keyMoment,
          referenceId: moments[2].id,
        ),
        const StoryExperiencePlanDraftStep(
          type: StoryExperienceStepType.music,
        ),
        const StoryExperiencePlanDraftStep(
          type: StoryExperienceStepType.reflection,
        ),
      ],
      providerLabel: 'in_memory',
      processingVersion: StoryExperiencePlan.defaultProcessingVersion,
    );
  }

  static StoryExperienceIntention _intentionFor(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('remember') || lower.contains('memory')) {
      return StoryExperienceIntention.remember;
    }
    if (lower.contains('connect') || lower.contains('together')) {
      return StoryExperienceIntention.connect;
    }
    if (lower.contains('encourage') || lower.contains('support')) {
      return StoryExperienceIntention.encourage;
    }
    if (lower.contains('reflect') || lower.contains('learned')) {
      return StoryExperienceIntention.reflect;
    }
    return StoryExperienceIntention.inspire;
  }

  static StoryExperienceArc _arcFor(
    String text,
    CapturedStoryReading reading,
  ) {
    final lower = '${text.toLowerCase()} ${reading.movement.text.toLowerCase()}';
    if (lower.contains('service') || lower.contains('military')) {
      return StoryExperienceArc.service;
    }
    if (lower.contains('remember') || lower.contains('loss')) {
      return StoryExperienceArc.remembrance;
    }
    if (lower.contains('persever') || lower.contains('keep going')) {
      return StoryExperienceArc.perseverance;
    }
    if (lower.contains('transform') || lower.contains('change')) {
      return StoryExperienceArc.transformation;
    }
    if (lower.contains('discover') || lower.contains('found')) {
      return StoryExperienceArc.discovery;
    }
    if (lower.contains('connect') || lower.contains('friend')) {
      return StoryExperienceArc.connection;
    }
    return StoryExperienceArc.challenge;
  }
}

import 'package:everyonesheroes/core/ids/story_experience_plan_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_arc.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_intention.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_step_type.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_moment.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_music_direction.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_step.dart';

/// Derived Story Experience Plan (HS.12.4 / HS-ADR-073).
///
/// Presentation guidance derived from an owned [Story] and its
/// [CapturedStoryReading]. Never modifies the canonical Story or reading.
///
/// Schema is narrative/presentation structure only — no personality, diagnosis,
/// trauma, attachment style, mental-health, or inferred motivation fields.
/// Music direction is guidance, not generated audio.
final class StoryExperiencePlan extends ValueObject {
  StoryExperiencePlan({
    required this.id,
    required this.storyId,
    required this.transcriptRepresentationId,
    required this.intention,
    required String coreMessage,
    required this.emotionalArc,
    required Iterable<StoryExperienceMoment> keyMoments,
    required this.musicDirection,
    required String reflectionPrompt,
    required Iterable<StoryExperienceStep> sequence,
    required this.createdAt,
    this.providerLabel,
    this.processingVersion = defaultProcessingVersion,
  })  : coreMessage = coreMessage.trim(),
        reflectionPrompt = reflectionPrompt.trim(),
        keyMoments = List.unmodifiable(keyMoments.toList()),
        sequence = List.unmodifiable(sequence.toList()) {
    if (this.coreMessage.isEmpty) {
      throw ArgumentError('coreMessage cannot be empty.');
    }
    if (this.coreMessage.length > maxCoreMessageLength) {
      throw ArgumentError(
        'coreMessage exceeds $maxCoreMessageLength characters.',
      );
    }
    if (this.reflectionPrompt.isEmpty) {
      throw ArgumentError('reflectionPrompt cannot be empty.');
    }
    if (this.reflectionPrompt.length > maxReflectionPromptLength) {
      throw ArgumentError(
        'reflectionPrompt exceeds $maxReflectionPromptLength characters.',
      );
    }
    if (this.keyMoments.isEmpty) {
      throw ArgumentError(
        'StoryExperiencePlan requires at least one key moment.',
      );
    }
    if (this.keyMoments.length > maxKeyMoments) {
      throw ArgumentError(
        'StoryExperiencePlan may have at most $maxKeyMoments key moments.',
      );
    }
    if (this.sequence.isEmpty) {
      throw ArgumentError('StoryExperiencePlan requires a non-empty sequence.');
    }
    final version = processingVersion.trim();
    if (version.isEmpty) {
      throw ArgumentError('processingVersion cannot be blank.');
    }

    final momentIds = <String>{};
    for (final moment in this.keyMoments) {
      if (!momentIds.add(moment.id)) {
        throw ArgumentError(
          'Duplicate key moment id "${moment.id}".',
        );
      }
      if (moment.sourceSpan.representationId != transcriptRepresentationId) {
        throw ArgumentError(
          'Key moment "${moment.id}" source span must reference the plan '
          'transcript representation.',
        );
      }
    }

    var hasStoryDerivedStep = false;
    for (final step in this.sequence) {
      switch (step.type) {
        case StoryExperienceStepType.story:
          hasStoryDerivedStep = true;
          if (step.referenceId != null && step.referenceId != storyId.value) {
            throw ArgumentError(
              'story step referenceId must be null or match storyId.',
            );
          }
        case StoryExperienceStepType.keyMoment:
          hasStoryDerivedStep = true;
          final ref = step.referenceId;
          if (ref == null || !momentIds.contains(ref)) {
            throw ArgumentError(
              'keyMoment step referenceId "$ref" does not match a key moment.',
            );
          }
        case StoryExperienceStepType.reflection:
        case StoryExperienceStepType.music:
          // Optional referenceId ignored for v1 plan runtime.
          break;
      }
    }

    if (!hasStoryDerivedStep) {
      throw ArgumentError(
        'StoryExperiencePlan sequence must include at least one story or '
        'keyMoment step.',
      );
    }
  }

  static const String defaultProcessingVersion = 'hs12.4.v1';
  static const int maxKeyMoments = 12;
  static const int maxCoreMessageLength = 500;
  static const int maxReflectionPromptLength = 500;

  final StoryExperiencePlanId id;
  final StoryId storyId;
  final StoryRepresentationId transcriptRepresentationId;
  final StoryExperienceIntention intention;
  final String coreMessage;
  final StoryExperienceArc emotionalArc;
  final List<StoryExperienceMoment> keyMoments;
  final StoryExperienceMusicDirection musicDirection;
  final String reflectionPrompt;
  final List<StoryExperienceStep> sequence;
  final DateTime createdAt;
  final String? providerLabel;
  final String processingVersion;

  /// Validates that every key-moment span lies within [transcriptText].
  ///
  /// Throws [ArgumentError] when any span is out of bounds. Callers that
  /// receive untrusted AI output must invoke this before persisting.
  void assertSpansWithinTranscript(String transcriptText) {
    final length = transcriptText.length;
    for (final moment in keyMoments) {
      final start = moment.sourceSpan.startOffset;
      final end = moment.sourceSpan.endOffset;
      if (start == null || end == null) {
        throw ArgumentError(
          'keyMoment "${moment.id}" is missing character offsets.',
        );
      }
      if (start < 0 || end > length || start > end) {
        throw ArgumentError(
          'keyMoment "${moment.id}" source span [$start, $end] is outside '
          'transcript (length $length).',
        );
      }
    }
  }

  @override
  List<Object?> get equalityProps => [
        id,
        storyId,
        transcriptRepresentationId,
        intention,
        coreMessage,
        emotionalArc,
        keyMoments,
        musicDirection,
        reflectionPrompt,
        sequence,
        createdAt,
        providerLabel,
        processingVersion,
      ];
}

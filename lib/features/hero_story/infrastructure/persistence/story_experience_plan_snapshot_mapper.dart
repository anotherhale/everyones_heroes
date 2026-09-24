import 'package:everyonesheroes/core/ids/story_experience_plan_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_arc.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_intention.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_step_type.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/source_span_reference.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_moment.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_music_direction.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_plan.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_step.dart';

/// JSON snapshot mapper for durable [StoryExperiencePlan] persistence.
abstract final class StoryExperiencePlanSnapshotMapper {
  static Map<String, dynamic> toJson(StoryExperiencePlan plan) {
    return {
      'id': plan.id.value,
      'storyId': plan.storyId.value,
      'transcriptRepresentationId': plan.transcriptRepresentationId.value,
      'intention': plan.intention.name,
      'coreMessage': plan.coreMessage,
      'emotionalArc': plan.emotionalArc.name,
      'keyMoments': [
        for (final moment in plan.keyMoments) _momentToJson(moment),
      ],
      'musicDirection': {
        'mood': plan.musicDirection.mood,
        'energy': plan.musicDirection.energy,
        'style': plan.musicDirection.style,
        'rationale': plan.musicDirection.rationale,
      },
      'reflectionPrompt': plan.reflectionPrompt,
      'sequence': [
        for (final step in plan.sequence)
          {
            'type': step.type.name,
            'referenceId': step.referenceId,
          },
      ],
      'createdAt': plan.createdAt.toIso8601String(),
      'providerLabel': plan.providerLabel,
      'processingVersion': plan.processingVersion,
    };
  }

  static StoryExperiencePlan fromJson(Map<String, dynamic> json) {
    final momentsRaw = json['keyMoments'];
    if (momentsRaw is! List) {
      throw const FormatException(
        'StoryExperiencePlan.keyMoments must be a list.',
      );
    }
    final sequenceRaw = json['sequence'];
    if (sequenceRaw is! List) {
      throw const FormatException(
        'StoryExperiencePlan.sequence must be a list.',
      );
    }
    final musicRaw = json['musicDirection'];
    if (musicRaw is! Map) {
      throw const FormatException(
        'StoryExperiencePlan.musicDirection must be an object.',
      );
    }
    final music = Map<String, dynamic>.from(musicRaw);

    return StoryExperiencePlan(
      id: StoryExperiencePlanId(json['id'] as String),
      storyId: StoryId(json['storyId'] as String),
      transcriptRepresentationId: StoryRepresentationId(
        json['transcriptRepresentationId'] as String,
      ),
      intention: StoryExperienceIntention.values.byName(
        json['intention'] as String,
      ),
      coreMessage: json['coreMessage'] as String,
      emotionalArc: StoryExperienceArc.values.byName(
        json['emotionalArc'] as String,
      ),
      keyMoments: [
        for (final raw in momentsRaw)
          _momentFromJson(Map<String, dynamic>.from(raw as Map)),
      ],
      musicDirection: StoryExperienceMusicDirection(
        mood: music['mood'] as String,
        energy: music['energy'] as String,
        style: music['style'] as String,
        rationale: music['rationale'] as String,
      ),
      reflectionPrompt: json['reflectionPrompt'] as String,
      sequence: [
        for (final raw in sequenceRaw)
          StoryExperienceStep(
            type: StoryExperienceStepType.values.byName(
              (raw as Map)['type'] as String,
            ),
            referenceId: raw['referenceId'] as String?,
          ),
      ],
      createdAt: DateTime.parse(json['createdAt'] as String),
      providerLabel: json['providerLabel'] as String?,
      processingVersion: json['processingVersion'] as String? ??
          StoryExperiencePlan.defaultProcessingVersion,
    );
  }

  static Map<String, dynamic> _momentToJson(StoryExperienceMoment moment) {
    return {
      'id': moment.id,
      'description': moment.description,
      'sourceSpan': _spanToJson(moment.sourceSpan),
    };
  }

  static StoryExperienceMoment _momentFromJson(Map<String, dynamic> json) {
    return StoryExperienceMoment(
      id: json['id'] as String,
      description: json['description'] as String,
      sourceSpan: _spanFromJson(
        Map<String, dynamic>.from(json['sourceSpan'] as Map),
      ),
    );
  }

  static Map<String, dynamic> _spanToJson(SourceSpanReference span) {
    return {
      'representationId': span.representationId.value,
      'startOffset': span.startOffset,
      'endOffset': span.endOffset,
      'startTimestampMs': span.startTimestampMs,
      'endTimestampMs': span.endTimestampMs,
      'opaquePosition': span.opaquePosition,
    };
  }

  static SourceSpanReference _spanFromJson(Map<String, dynamic> json) {
    return SourceSpanReference(
      representationId: StoryRepresentationId(
        json['representationId'] as String,
      ),
      startOffset: json['startOffset'] as int?,
      endOffset: json['endOffset'] as int?,
      startTimestampMs: json['startTimestampMs'] as int?,
      endTimestampMs: json['endTimestampMs'] as int?,
      opaquePosition: json['opaquePosition'] as String?,
    );
  }
}

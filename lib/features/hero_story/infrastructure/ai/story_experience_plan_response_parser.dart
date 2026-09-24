import 'dart:convert';

import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_arc.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_intention.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_step_type.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_experience_planner_port.dart';

/// Parses and validates EH-owned Story Experience Plan JSON (HS.12.4).
///
/// Rejects malformed output, invalid enums, invalid spans, out-of-range
/// offsets, and psychological-claim fields. Never silently repairs invalid AI
/// output.
abstract final class StoryExperiencePlanResponseParser {
  static const Set<String> forbiddenTopLevelKeys = {
    'personality',
    'attachmentStyle',
    'trauma',
    'traumaLevel',
    'mentalHealth',
    'diagnosis',
    'resilienceScore',
    'emotionalHealth',
    'psychologicalState',
    'personalityTraits',
    'psychologicalProfile',
    'inferredMotivation',
    'inferredBehavioralTendencies',
    'motivation',
    'behavioralTendencies',
    'mentalHealthAssessment',
  };

  static StoryExperiencePlanDraft parse(
    String body, {
    required String transcriptText,
    required String storyId,
  }) {
    late final Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        throw const FormatException('Expected JSON object');
      }
      json = Map<String, dynamic>.from(decoded);
    } on FormatException catch (e) {
      throw StoryExperiencePlannerException(
        'Malformed Story Experience Plan response: $e',
      );
    }

    for (final key in forbiddenTopLevelKeys) {
      if (json.containsKey(key)) {
        throw StoryExperiencePlannerException(
          'Story Experience Plan must not include psychological field "$key".',
        );
      }
    }

    final intention = _parseIntention(json['intention']);
    final emotionalArc = _parseArc(json['emotionalArc']);
    final coreMessage = (json['coreMessage'] as String?)?.trim() ?? '';
    if (coreMessage.isEmpty) {
      throw const StoryExperiencePlannerException(
        'Story Experience Plan requires non-empty coreMessage.',
      );
    }
    final reflectionPrompt =
        (json['reflectionPrompt'] as String?)?.trim() ?? '';
    if (reflectionPrompt.isEmpty) {
      throw const StoryExperiencePlannerException(
        'Story Experience Plan requires non-empty reflectionPrompt.',
      );
    }

    final musicRaw = json['musicDirection'];
    if (musicRaw is! Map) {
      throw const StoryExperiencePlannerException(
        'Story Experience Plan requires musicDirection object.',
      );
    }
    final musicMap = Map<String, dynamic>.from(musicRaw);
    for (final key in forbiddenTopLevelKeys) {
      if (musicMap.containsKey(key)) {
        throw StoryExperiencePlannerException(
          'musicDirection must not include psychological field "$key".',
        );
      }
    }
    final music = StoryExperiencePlanDraftMusicDirection(
      mood: (musicMap['mood'] as String?)?.trim() ?? '',
      energy: (musicMap['energy'] as String?)?.trim() ?? '',
      style: (musicMap['style'] as String?)?.trim() ?? '',
      rationale: (musicMap['rationale'] as String?)?.trim() ?? '',
    );
    if (music.mood.isEmpty ||
        music.energy.isEmpty ||
        music.style.isEmpty ||
        music.rationale.isEmpty) {
      throw const StoryExperiencePlannerException(
        'musicDirection requires non-empty mood, energy, style, and rationale.',
      );
    }

    final momentsRaw = json['keyMoments'];
    if (momentsRaw is! List || momentsRaw.isEmpty) {
      throw const StoryExperiencePlannerException(
        'Story Experience Plan requires a non-empty keyMoments list.',
      );
    }

    final length = transcriptText.length;
    final moments = <StoryExperiencePlanDraftMoment>[];
    final momentIds = <String>{};
    for (var i = 0; i < momentsRaw.length; i++) {
      final item = momentsRaw[i];
      if (item is! Map) {
        throw StoryExperiencePlannerException(
          'keyMoments[$i] must be a JSON object.',
        );
      }
      final moment = _parseMoment(
        Map<String, dynamic>.from(item),
        index: i,
        transcriptLength: length,
      );
      if (!momentIds.add(moment.id)) {
        throw StoryExperiencePlannerException(
          'Duplicate key moment id "${moment.id}".',
        );
      }
      moments.add(moment);
    }

    final sequenceRaw = json['sequence'];
    if (sequenceRaw is! List || sequenceRaw.isEmpty) {
      throw const StoryExperiencePlannerException(
        'Story Experience Plan requires a non-empty sequence list.',
      );
    }
    final sequence = <StoryExperiencePlanDraftStep>[];
    var hasStoryDerived = false;
    for (var i = 0; i < sequenceRaw.length; i++) {
      final item = sequenceRaw[i];
      if (item is! Map) {
        throw StoryExperiencePlannerException(
          'sequence[$i] must be a JSON object.',
        );
      }
      final step = _parseStep(
        Map<String, dynamic>.from(item),
        index: i,
        momentIds: momentIds,
        storyId: storyId,
      );
      if (step.type == StoryExperienceStepType.story ||
          step.type == StoryExperienceStepType.keyMoment) {
        hasStoryDerived = true;
      }
      sequence.add(step);
    }
    if (!hasStoryDerived) {
      throw const StoryExperiencePlannerException(
        'sequence must include at least one story or keyMoment step.',
      );
    }

    return StoryExperiencePlanDraft(
      intention: intention,
      coreMessage: coreMessage,
      emotionalArc: emotionalArc,
      keyMoments: moments,
      musicDirection: music,
      reflectionPrompt: reflectionPrompt,
      sequence: sequence,
      providerLabel: json['providerLabel'] as String?,
      processingVersion: json['processingVersion'] as String?,
    );
  }

  static StoryExperienceIntention _parseIntention(Object? raw) {
    if (raw is! String || raw.trim().isEmpty) {
      throw const StoryExperiencePlannerException(
        'Story Experience Plan requires intention enum.',
      );
    }
    return StoryExperienceIntention.values.firstWhere(
      (v) => v.name == raw.trim(),
      orElse: () => throw StoryExperiencePlannerException(
        'Invalid StoryExperienceIntention "$raw".',
      ),
    );
  }

  static StoryExperienceArc _parseArc(Object? raw) {
    if (raw is! String || raw.trim().isEmpty) {
      throw const StoryExperiencePlannerException(
        'Story Experience Plan requires emotionalArc enum.',
      );
    }
    return StoryExperienceArc.values.firstWhere(
      (v) => v.name == raw.trim(),
      orElse: () => throw StoryExperiencePlannerException(
        'Invalid StoryExperienceArc "$raw".',
      ),
    );
  }

  static StoryExperiencePlanDraftMoment _parseMoment(
    Map<String, dynamic> map, {
    required int index,
    required int transcriptLength,
  }) {
    final id = (map['id'] as String?)?.trim() ?? '';
    if (id.isEmpty) {
      throw StoryExperiencePlannerException(
        'keyMoments[$index].id cannot be empty.',
      );
    }
    final description = (map['description'] as String?)?.trim() ?? '';
    if (description.isEmpty) {
      throw StoryExperiencePlannerException(
        'keyMoments[$index].description cannot be empty.',
      );
    }
    final span = map['sourceSpan'];
    if (span is! Map) {
      throw StoryExperiencePlannerException(
        'keyMoments[$index] requires sourceSpan.',
      );
    }
    final start = span['startOffset'];
    final end = span['endOffset'];
    if (start is! int || end is! int) {
      throw StoryExperiencePlannerException(
        'keyMoments[$index] sourceSpan requires integer offsets.',
      );
    }
    _assertSpan('keyMoments[$index]', start, end, transcriptLength);

    return StoryExperiencePlanDraftMoment(
      id: id,
      description: description,
      startOffset: start,
      endOffset: end,
      startTimestampMs: span['startTimestampMs'] as int?,
      endTimestampMs: span['endTimestampMs'] as int?,
    );
  }

  static StoryExperiencePlanDraftStep _parseStep(
    Map<String, dynamic> map, {
    required int index,
    required Set<String> momentIds,
    required String storyId,
  }) {
    final typeRaw = map['type'];
    if (typeRaw is! String || typeRaw.trim().isEmpty) {
      throw StoryExperiencePlannerException(
        'sequence[$index] requires type.',
      );
    }
    final type = StoryExperienceStepType.values.firstWhere(
      (v) => v.name == typeRaw.trim(),
      orElse: () => throw StoryExperiencePlannerException(
        'Unsupported sequence type "${typeRaw.trim()}" at sequence[$index].',
      ),
    );
    final referenceId = (map['referenceId'] as String?)?.trim();
    final ref = (referenceId == null || referenceId.isEmpty) ? null : referenceId;

    switch (type) {
      case StoryExperienceStepType.story:
        if (ref != null && ref != storyId) {
          throw StoryExperiencePlannerException(
            'sequence[$index] story referenceId must match storyId.',
          );
        }
      case StoryExperienceStepType.keyMoment:
        if (ref == null || !momentIds.contains(ref)) {
          throw StoryExperiencePlannerException(
            'sequence[$index] keyMoment referenceId "$ref" is invalid.',
          );
        }
      case StoryExperienceStepType.reflection:
      case StoryExperienceStepType.music:
        break;
    }

    return StoryExperiencePlanDraftStep(type: type, referenceId: ref);
  }

  static void _assertSpan(
    String name,
    int start,
    int end,
    int transcriptLength,
  ) {
    if (start < 0 || end < start || end > transcriptLength) {
      throw StoryExperiencePlannerException(
        'Story Experience Plan "$name" source span [$start, $end] is outside '
        'transcript (length $transcriptLength).',
      );
    }
  }
}

import 'dart:convert';

import 'package:eh_platform/src/life_journey/domain/domain.dart';
import 'package:eh_platform/src/life_journey/domain/enums/reflection_emotion.dart';
import 'package:eh_platform/src/shared_kernel/ids/assessment_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/coaching_session_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/discovery_activity_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/mission_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/narrative_theme_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/quest_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/reflection_id.dart';

/// JSON serialization for H.2 persistence (Journey patterns + Reflection state).
final class H2JsonCodec {
  const H2JsonCodec();

  List<Map<String, Object?>> encodePatterns(List<BehaviorPattern> patterns) {
    return patterns.map(encodePattern).toList(growable: false);
  }

  List<BehaviorPattern> decodePatterns(Object? raw) {
    final list = _asList(raw);
    return list.map((e) => decodePattern(e as Map)).toList(growable: false);
  }

  Map<String, Object?> encodePattern(BehaviorPattern pattern) {
    return {
      'type': pattern.type.name,
      'strength': pattern.strength.value,
      'supportingEvidence': pattern.supportingEvidence
          .map(encodeEvidence)
          .toList(),
      'firstObservedAt': pattern.firstObservedAt.toUtc().toIso8601String(),
      'lastObservedAt': pattern.lastObservedAt.toUtc().toIso8601String(),
    };
  }

  BehaviorPattern decodePattern(Map raw) {
    final evidence = (raw['supportingEvidence'] as List)
        .map((e) => decodeEvidence(e as Map))
        .toList(growable: false);
    return BehaviorPattern(
      type: BehaviorPatternType.values.byName(raw['type'] as String),
      strength: Strength((raw['strength'] as num).toDouble()),
      supportingEvidence: evidence,
      firstObservedAt: DateTime.parse(raw['firstObservedAt'] as String),
      lastObservedAt: DateTime.parse(raw['lastObservedAt'] as String),
    );
  }

  Map<String, Object?> encodeEvidence(BehavioralEvidence evidence) {
    return {
      'type': evidence.type.name,
      'strength': evidence.strength.value,
      'observedAt': evidence.observedAt.toUtc().toIso8601String(),
      'source': encodeSource(evidence.source),
    };
  }

  BehavioralEvidence decodeEvidence(Map raw) {
    return BehavioralEvidence(
      type: BehavioralEvidenceType.values.byName(raw['type'] as String),
      strength: Strength((raw['strength'] as num).toDouble()),
      observedAt: DateTime.parse(raw['observedAt'] as String),
      source: decodeSource(raw['source'] as Map),
    );
  }

  Map<String, Object?> encodeSource(EvidenceSource source) {
    return switch (source) {
      ReflectionEvidenceSource(:final reflectionId) => {
        'kind': 'reflection',
        'id': reflectionId.value,
      },
      MissionEvidenceSource(:final missionId) => {
        'kind': 'mission',
        'id': missionId.value,
      },
      DiscoveryEvidenceSource(:final discoveryActivityId) => {
        'kind': 'discovery',
        'id': discoveryActivityId.value,
      },
      AssessmentEvidenceSource(:final assessmentId) => {
        'kind': 'assessment',
        'id': assessmentId.value,
      },
      CoachingEvidenceSource(:final coachingSessionId) => {
        'kind': 'coaching',
        'id': coachingSessionId.value,
      },
    };
  }

  EvidenceSource decodeSource(Map raw) {
    final id = raw['id'] as String;
    return switch (raw['kind'] as String) {
      'reflection' => ReflectionEvidenceSource(reflectionId: ReflectionId(id)),
      'mission' => MissionEvidenceSource(missionId: MissionId(id)),
      'discovery' => DiscoveryEvidenceSource(
        discoveryActivityId: DiscoveryActivityId(id),
      ),
      'assessment' => AssessmentEvidenceSource(assessmentId: AssessmentId(id)),
      'coaching' => CoachingEvidenceSource(
        coachingSessionId: CoachingSessionId(id),
      ),
      final kind => throw FormatException(
        'Unknown evidence source kind: $kind',
      ),
    };
  }

  List<Map<String, Object?>> encodeResponses(
    List<ReflectionResponse> responses,
  ) {
    return responses.map(encodeResponse).toList(growable: false);
  }

  List<ReflectionResponse> decodeResponses(Object? raw) {
    final list = _asList(raw);
    return list.map((e) => decodeResponse(e as Map)).toList(growable: false);
  }

  Map<String, Object?> encodeResponse(ReflectionResponse response) {
    return switch (response) {
      EmojiResponse(:final emotion) => {
        'type': 'emoji',
        'emotion': emotion.name,
      },
      JournalResponse(:final prompt, :final response, :final emotion) => {
        'type': 'journal',
        'prompt': prompt,
        'response': response,
        'emotion': emotion.name,
      },
      PromptResponse(:final prompt, :final response) => {
        'type': 'prompt',
        'prompt': prompt,
        'response': response,
      },
      ScaleResponse(:final value, :final maxValue) => {
        'type': 'scale',
        'value': value,
        'maxValue': maxValue,
      }, // value/maxValue are ints in domain
      ChoiceResponse(:final question, :final selectedOption, :final options) =>
        {
          'type': 'choice',
          'question': question,
          'selectedOption': selectedOption,
          'options': options,
        },
      VoiceResponse(
        :final transcript,
        :final durationSeconds,
        :final audioReference,
      ) =>
        {
          'type': 'voice',
          'transcript': transcript,
          'durationSeconds': durationSeconds,
          'audioReference': audioReference,
        },
      PhotoResponse(:final photoReference, :final caption) => {
        'type': 'photo',
        'photoReference': photoReference,
        'caption': caption,
      },
      _ => throw FormatException(
        'Unsupported reflection response: ${response.runtimeType}',
      ),
    };
  }

  ReflectionResponse decodeResponse(Map raw) {
    return switch (raw['type'] as String) {
      'emoji' => EmojiResponse(
        emotion: ReflectionEmotion.values.byName(raw['emotion'] as String),
      ),
      'journal' => JournalResponse(
        prompt: raw['prompt'] as String?,
        response: raw['response'] as String,
        emotion: ReflectionEmotion.values.byName(
          (raw['emotion'] as String?) ?? 'neutral',
        ),
      ),
      'prompt' => PromptResponse(
        prompt: raw['prompt'] as String,
        response: raw['response'] as String,
      ),
      'scale' => ScaleResponse(
        value: (raw['value'] as num).toInt(),
        maxValue: (raw['maxValue'] as num?)?.toInt() ?? 10,
      ),
      'choice' => ChoiceResponse(
        question: raw['question'] as String,
        selectedOption: raw['selectedOption'] as String,
        options: (raw['options'] as List).cast<String>(),
      ),
      'voice' => VoiceResponse(
        transcript: raw['transcript'] as String,
        durationSeconds: (raw['durationSeconds'] as num?)?.toInt(),
        audioReference: raw['audioReference'] as String?,
      ),
      'photo' => PhotoResponse(
        photoReference: raw['photoReference'] as String,
        caption: raw['caption'] as String?,
      ),
      final kind => throw FormatException('Unknown response type: $kind'),
    };
  }

  List<Map<String, Object?>> encodeInsights(List<Insight> insights) {
    return insights
        .map((i) => {'statement': i.statement, 'confidence': i.confidence})
        .toList(growable: false);
  }

  List<Insight> decodeInsights(Object? raw) {
    return _asList(raw)
        .map(
          (e) => Insight(
            statement: (e as Map)['statement'] as String,
            confidence: (e['confidence'] as num).toDouble(),
          ),
        )
        .toList(growable: false);
  }

  List<String> encodeThemeIds(List<NarrativeThemeId> themes) {
    return themes.map((t) => t.value).toList(growable: false);
  }

  List<NarrativeThemeId> decodeThemeIds(Object? raw) {
    return _asList(
      raw,
    ).map((e) => NarrativeThemeId(e as String)).toList(growable: false);
  }

  List<String> encodeQuestIds(List<QuestId> ids) {
    return ids.map((q) => q.value).toList(growable: false);
  }

  List<QuestId> decodeQuestIds(Object? raw) {
    return _asList(
      raw,
    ).map((e) => QuestId(e as String)).toList(growable: false);
  }

  List<Map<String, Object?>> encodeEvidenceList(
    List<BehavioralEvidence> evidence,
  ) {
    return evidence.map(encodeEvidence).toList(growable: false);
  }

  List<BehavioralEvidence> decodeEvidenceList(Object? raw) {
    return _asList(
      raw,
    ).map((e) => decodeEvidence(e as Map)).toList(growable: false);
  }

  String encodeJson(Object value) => jsonEncode(value);

  List<dynamic> _asList(Object? raw) {
    if (raw == null) {
      return const [];
    }
    if (raw is List) {
      return raw;
    }
    if (raw is String) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded;
      }
    }
    throw FormatException('Expected JSON list, got ${raw.runtimeType}');
  }
}

import 'dart:convert';

import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_narrative_role.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_builder_coach_port.dart';

/// Parses EH-owned Story Coach JSON (not raw OpenAI shapes).
abstract final class StoryBuilderCoachResponseParser {
  static StoryBuilderCoachSuggestion parse(String rawBody) {
    late final Object? decoded;
    try {
      decoded = jsonDecode(rawBody);
    } on FormatException catch (e) {
      throw StoryBuilderCoachException(
        'Malformed AI Story Coach response: $e',
      );
    }

    if (decoded is! Map) {
      throw const StoryBuilderCoachException(
        'AI Story Coach response must be a JSON object.',
      );
    }

    return parseMap(Map<String, dynamic>.from(decoded));
  }

  static StoryBuilderCoachSuggestion parseMap(Map<String, dynamic> json) {
    final readyRaw = json['readyToComplete'];
    if (readyRaw != null && readyRaw is! bool) {
      throw const StoryBuilderCoachException(
        'AI Story Coach readyToComplete must be a boolean.',
      );
    }
    final readyToComplete = readyRaw as bool? ?? false;

    final questionRaw = json['question'];
    if (questionRaw != null && questionRaw is! String) {
      throw const StoryBuilderCoachException(
        'AI Story Coach question must be a string.',
      );
    }
    final question = (questionRaw as String?)?.trim();

    if (!readyToComplete && (question == null || question.isEmpty)) {
      throw const StoryBuilderCoachException(
        'AI Story Coach response missing question.',
      );
    }

    final roleRaw = json['narrativeRole'];
    if (roleRaw != null && roleRaw is! String) {
      throw const StoryBuilderCoachException(
        'AI Story Coach narrativeRole must be a string.',
      );
    }

    StoryBuilderNarrativeRole? role;
    if (roleRaw is String && roleRaw.isNotEmpty) {
      try {
        role = StoryBuilderNarrativeRole.values.byName(roleRaw);
      } on ArgumentError {
        throw StoryBuilderCoachException(
          'AI Story Coach returned invalid narrativeRole: $roleRaw',
        );
      }
    }

    final reasonRaw = json['reason'];
    if (reasonRaw != null && reasonRaw is! String) {
      throw const StoryBuilderCoachException(
        'AI Story Coach reason must be a string.',
      );
    }

    return StoryBuilderCoachSuggestion(
      question: question == null || question.isEmpty ? null : question,
      narrativeRole: role,
      reason: reasonRaw as String?,
      readyToComplete: readyToComplete,
    );
  }
}

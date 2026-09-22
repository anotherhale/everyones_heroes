import 'dart:convert';

import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_narrative_role.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_authoring_transport.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_shaper_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal.dart';

/// Parses EH-owned Story Authoring JSON (SB.11) — not raw OpenAI shapes.
///
/// Rejects malformed JSON, unknown narrative roles, and invalid types.
/// Does not validate sourceResponseIds against a proposal — that belongs to
/// [AiStoryShaper]. Does not trust AI for lifecycle or contentOrigin.
abstract final class StoryAuthoringResponseParser {
  static const int maxSections = 24;
  static const int maxWarnings = 20;
  static const int maxContentLength = 8000;
  static const int maxWarningLength = 400;

  static StoryAuthoringResponse parse(String rawBody) {
    late final Object? decoded;
    try {
      decoded = jsonDecode(rawBody);
    } on FormatException catch (e) {
      throw StoryShaperException(
        'Malformed AI story authoring response: $e',
      );
    }

    if (decoded is! Map) {
      throw const StoryShaperException(
        'AI story authoring response must be a JSON object.',
      );
    }

    return parseMap(Map<String, dynamic>.from(decoded));
  }

  static StoryAuthoringResponse parseMap(Map<String, dynamic> json) {
    // Ignore AI attempts to control lifecycle / contentOrigin.
    final title = _optionalBoundedString(
      json['title'],
      field: 'title',
      maxLength: 300,
    );
    final summary = _optionalBoundedString(
      json['summary'],
      field: 'summary',
      maxLength: StoryProposal.maxDerivedSummaryLength,
    );
    final sections = _parseSections(json['sections']);
    final warnings = _parseWarnings(json['warnings']);
    final providerLabel = _optionalBoundedString(
      json['providerLabel'],
      field: 'providerLabel',
      maxLength: 120,
    );
    final modelLabel = _optionalBoundedString(
      json['modelLabel'],
      field: 'modelLabel',
      maxLength: 120,
    );
    final promptOrTemplateVersion = _optionalBoundedString(
      json['promptOrTemplateVersion'],
      field: 'promptOrTemplateVersion',
      maxLength: 80,
    );

    return StoryAuthoringResponse(
      title: title,
      summary: summary,
      sections: sections,
      warnings: warnings,
      providerLabel: providerLabel,
      modelLabel: modelLabel,
      promptOrTemplateVersion: promptOrTemplateVersion,
    );
  }

  static List<StoryAuthoringSectionOutput> _parseSections(Object? raw) {
    if (raw == null) {
      throw const StoryShaperException(
        'AI story authoring response is missing sections.',
      );
    }
    if (raw is! List) {
      throw const StoryShaperException(
        'AI story authoring sections must be a list.',
      );
    }
    if (raw.isEmpty) {
      throw const StoryShaperException(
        'AI story authoring sections list is empty.',
      );
    }
    if (raw.length > maxSections) {
      throw const StoryShaperException(
        'AI story authoring sections list is too large.',
      );
    }

    final result = <StoryAuthoringSectionOutput>[];
    for (final item in raw) {
      if (item is! Map) {
        throw const StoryShaperException(
          'AI story authoring section entries must be objects.',
        );
      }
      final map = Map<String, dynamic>.from(item);
      final roleRaw = map['role'] ?? map['narrativeRole'];
      if (roleRaw is! String || roleRaw.isEmpty) {
        throw const StoryShaperException(
          'AI story authoring section is missing role.',
        );
      }
      final role = _parseRole(roleRaw);
      final content = _optionalBoundedString(
        map['content'],
        field: 'content',
        maxLength: maxContentLength,
      );
      final sourceIds = _parseSourceIds(map['sourceResponseIds']);

      result.add(
        StoryAuthoringSectionOutput(
          role: role,
          content: content,
          sourceResponseIds: sourceIds,
        ),
      );
    }
    return result;
  }

  static StoryBuilderNarrativeRole _parseRole(String raw) {
    try {
      return StoryBuilderNarrativeRole.values.byName(raw);
    } on ArgumentError {
      throw StoryShaperException(
        'AI story authoring returned unknown narrative role: $raw',
      );
    }
  }

  static List<StoryBuilderResponseId> _parseSourceIds(Object? raw) {
    if (raw == null) {
      throw const StoryShaperException(
        'AI story authoring section is missing sourceResponseIds.',
      );
    }
    if (raw is! List) {
      throw const StoryShaperException(
        'AI story authoring sourceResponseIds must be a list.',
      );
    }
    if (raw.isEmpty) {
      throw const StoryShaperException(
        'AI story authoring sourceResponseIds cannot be empty.',
      );
    }
    if (raw.length > 40) {
      throw const StoryShaperException(
        'AI story authoring sourceResponseIds list is too large.',
      );
    }
    final ids = <StoryBuilderResponseId>[];
    for (final item in raw) {
      if (item is! String || item.trim().isEmpty) {
        throw const StoryShaperException(
          'AI story authoring returned a malformed sourceResponseId.',
        );
      }
      ids.add(StoryBuilderResponseId(item.trim()));
    }
    return ids;
  }

  static List<String> _parseWarnings(Object? raw) {
    if (raw == null) {
      return const [];
    }
    if (raw is! List) {
      throw const StoryShaperException(
        'AI story authoring warnings must be a list.',
      );
    }
    if (raw.length > maxWarnings) {
      throw const StoryShaperException(
        'AI story authoring warnings list is too large.',
      );
    }
    final result = <String>[];
    for (final item in raw) {
      if (item is! String) {
        throw const StoryShaperException(
          'AI story authoring warning entries must be strings.',
        );
      }
      final trimmed = item.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.length > maxWarningLength) {
        throw const StoryShaperException(
          'AI story authoring warning exceeds maximum length.',
        );
      }
      result.add(trimmed);
    }
    return result;
  }

  static String? _optionalBoundedString(
    Object? raw, {
    required String field,
    required int maxLength,
  }) {
    if (raw == null) return null;
    if (raw is! String) {
      throw StoryShaperException(
        'AI story authoring $field must be a string.',
      );
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length > maxLength) {
      throw StoryShaperException(
        'AI story authoring $field exceeds maximum length.',
      );
    }
    return trimmed;
  }
}

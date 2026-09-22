import 'dart:convert';

import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_narrative_role.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_theme.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/understood_theme_origin.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_builder_understanding_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/understood_claim.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/understood_key_story_elements.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/understood_narrative_element.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/understood_significant_event.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/understood_theme.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_understanding.dart';

/// Parses EH-owned Story Understanding JSON (not raw OpenAI shapes).
///
/// Rejects malformed JSON, unknown themes/roles, invalid types, and
/// oversized payloads. Does not validate response IDs against a session —
/// that belongs to [StoryBuilderUnderstandingProvenance].
abstract final class StoryBuilderUnderstandingResponseParser {
  static StoryBuilderUnderstandingDraft parse(String rawBody) {
    late final Object? decoded;
    try {
      decoded = jsonDecode(rawBody);
    } on FormatException catch (e) {
      throw StoryBuilderUnderstandingException(
        'Malformed AI Story Understanding response: $e',
      );
    }

    if (decoded is! Map) {
      throw const StoryBuilderUnderstandingException(
        'AI Story Understanding response must be a JSON object.',
      );
    }

    return parseMap(Map<String, dynamic>.from(decoded));
  }

  static StoryBuilderUnderstandingDraft parseMap(Map<String, dynamic> json) {
    final themes = _parseThemes(json['themes']);
    final narrativeElements = _parseNarrativeElements(json['narrativeElements']);
    final significantEvents = _parseEvents(json['significantEvents']);
    final keyElements = _parseKeyElements(json['keyElements']);
    final derivedSummary = _optionalBoundedString(
      json['derivedSummary'],
      field: 'derivedSummary',
      maxLength: StoryBuilderUnderstanding.maxDerivedSummaryLength,
    );
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

    return StoryBuilderUnderstandingDraft(
      themes: themes,
      narrativeElements: narrativeElements,
      keyElements: keyElements,
      significantEvents: significantEvents,
      derivedSummary: derivedSummary,
      providerLabel: providerLabel,
      modelLabel: modelLabel,
      promptOrTemplateVersion: promptOrTemplateVersion,
    );
  }

  static List<UnderstoodTheme> _parseThemes(Object? raw) {
    if (raw == null) {
      return const [];
    }
    if (raw is! List) {
      throw const StoryBuilderUnderstandingException(
        'AI Story Understanding themes must be a list.',
      );
    }
    if (raw.length > StoryBuilderUnderstanding.maxThemes) {
      throw const StoryBuilderUnderstandingException(
        'AI Story Understanding themes list is too large.',
      );
    }
    final result = <UnderstoodTheme>[];
    for (final item in raw) {
      if (item is! Map) {
        throw const StoryBuilderUnderstandingException(
          'AI Story Understanding theme entries must be objects.',
        );
      }
      final map = Map<String, dynamic>.from(item);
      final themeRaw = map['theme'];
      if (themeRaw is! String || themeRaw.isEmpty) {
        throw const StoryBuilderUnderstandingException(
          'AI Story Understanding theme requires a theme string.',
        );
      }
      late final StoryBuilderTheme theme;
      try {
        theme = StoryBuilderTheme.values.byName(themeRaw);
      } on ArgumentError {
        throw StoryBuilderUnderstandingException(
          'AI Story Understanding returned invalid theme: $themeRaw',
        );
      }
      final ids = _parseResponseIds(
        map['sourceResponseIds'],
        field: 'theme.sourceResponseIds',
      );
      result.add(
        UnderstoodTheme(
          theme: theme,
          origin: UnderstoodThemeOrigin.derivedFromResponses,
          sourceResponseIds: ids,
        ),
      );
    }
    return result;
  }

  static List<UnderstoodNarrativeElement> _parseNarrativeElements(Object? raw) {
    if (raw == null) {
      return const [];
    }
    if (raw is! List) {
      throw const StoryBuilderUnderstandingException(
        'AI Story Understanding narrativeElements must be a list.',
      );
    }
    if (raw.length > 22) {
      throw const StoryBuilderUnderstandingException(
        'AI Story Understanding narrativeElements list is too large.',
      );
    }
    final result = <UnderstoodNarrativeElement>[];
    for (final item in raw) {
      if (item is! Map) {
        throw const StoryBuilderUnderstandingException(
          'AI Story Understanding narrativeElement entries must be objects.',
        );
      }
      final map = Map<String, dynamic>.from(item);
      final role = _parseRole(map['narrativeRole'], field: 'narrativeRole');
      final ids = _parseResponseIds(
        map['sourceResponseIds'],
        field: 'narrativeElement.sourceResponseIds',
      );
      final note = _optionalBoundedString(
        map['derivedNote'],
        field: 'derivedNote',
        maxLength: UnderstoodNarrativeElement.maxDerivedNoteLength,
      );
      result.add(
        UnderstoodNarrativeElement(
          narrativeRole: role,
          sourceResponseIds: ids,
          derivedNote: note,
        ),
      );
    }
    return result;
  }

  static List<UnderstoodSignificantEvent> _parseEvents(Object? raw) {
    if (raw == null) {
      return const [];
    }
    if (raw is! List) {
      throw const StoryBuilderUnderstandingException(
        'AI Story Understanding significantEvents must be a list.',
      );
    }
    if (raw.length > StoryBuilderUnderstanding.maxSignificantEvents) {
      throw const StoryBuilderUnderstandingException(
        'AI Story Understanding significantEvents list is too large.',
      );
    }
    final result = <UnderstoodSignificantEvent>[];
    for (final item in raw) {
      if (item is! Map) {
        throw const StoryBuilderUnderstandingException(
          'AI Story Understanding significantEvent entries must be objects.',
        );
      }
      final map = Map<String, dynamic>.from(item);
      final labelRaw = map['label'];
      if (labelRaw is! String || labelRaw.trim().isEmpty) {
        throw const StoryBuilderUnderstandingException(
          'AI Story Understanding significantEvent requires a label.',
        );
      }
      final ids = _parseResponseIds(
        map['sourceResponseIds'],
        field: 'significantEvent.sourceResponseIds',
      );
      StoryBuilderNarrativeRole? role;
      if (map['narrativeRole'] != null) {
        role = _parseRole(map['narrativeRole'], field: 'significantEvent.narrativeRole');
      }
      result.add(
        UnderstoodSignificantEvent(
          label: labelRaw.trim(),
          sourceResponseIds: ids,
          narrativeRole: role,
        ),
      );
    }
    return result;
  }

  static UnderstoodKeyStoryElements _parseKeyElements(Object? raw) {
    if (raw == null) {
      return const UnderstoodKeyStoryElements();
    }
    if (raw is! Map) {
      throw const StoryBuilderUnderstandingException(
        'AI Story Understanding keyElements must be an object.',
      );
    }
    final map = Map<String, dynamic>.from(raw);
    return UnderstoodKeyStoryElements(
      challenge: _parseClaim(map['challenge'], field: 'challenge'),
      struggle: _parseClaim(map['struggle'], field: 'struggle'),
      stakes: _parseClaim(map['stakes'], field: 'stakes'),
      turningPoint: _parseClaim(map['turningPoint'], field: 'turningPoint'),
      decision: _parseClaim(map['decision'], field: 'decision'),
      action: _parseClaim(map['action'], field: 'action'),
      outcome: _parseClaim(map['outcome'], field: 'outcome'),
      reflection: _parseClaim(map['reflection'], field: 'reflection'),
      message: _parseClaim(map['message'], field: 'message'),
    );
  }

  static UnderstoodClaim? _parseClaim(Object? raw, {required String field}) {
    if (raw == null) {
      return null;
    }
    if (raw is! Map) {
      throw StoryBuilderUnderstandingException(
        'AI Story Understanding $field must be an object.',
      );
    }
    final map = Map<String, dynamic>.from(raw);
    final ids = _parseResponseIds(
      map['sourceResponseIds'],
      field: '$field.sourceResponseIds',
    );
    final interpretation = _optionalBoundedString(
      map['derivedInterpretation'],
      field: '$field.derivedInterpretation',
      maxLength: UnderstoodClaim.maxDerivedInterpretationLength,
    );
    return UnderstoodClaim(
      sourceResponseIds: ids,
      derivedInterpretation: interpretation,
    );
  }

  static StoryBuilderNarrativeRole _parseRole(
    Object? raw, {
    required String field,
  }) {
    if (raw is! String || raw.isEmpty) {
      throw StoryBuilderUnderstandingException(
        'AI Story Understanding $field must be a non-empty string.',
      );
    }
    try {
      return StoryBuilderNarrativeRole.values.byName(raw);
    } on ArgumentError {
      throw StoryBuilderUnderstandingException(
        'AI Story Understanding returned invalid narrative role: $raw',
      );
    }
  }

  static List<StoryBuilderResponseId> _parseResponseIds(
    Object? raw, {
    required String field,
  }) {
    if (raw == null) {
      throw StoryBuilderUnderstandingException(
        'AI Story Understanding $field is required.',
      );
    }
    if (raw is! List) {
      throw StoryBuilderUnderstandingException(
        'AI Story Understanding $field must be a list.',
      );
    }
    if (raw.isEmpty) {
      throw StoryBuilderUnderstandingException(
        'AI Story Understanding $field cannot be empty.',
      );
    }
    if (raw.length > 40) {
      throw StoryBuilderUnderstandingException(
        'AI Story Understanding $field is too large.',
      );
    }
    final ids = <StoryBuilderResponseId>[];
    for (final item in raw) {
      if (item is! String || item.trim().isEmpty) {
        throw StoryBuilderUnderstandingException(
          'AI Story Understanding $field entries must be non-empty strings.',
        );
      }
      ids.add(StoryBuilderResponseId(item.trim()));
    }
    return ids;
  }

  static String? _optionalBoundedString(
    Object? raw, {
    required String field,
    required int maxLength,
  }) {
    if (raw == null) {
      return null;
    }
    if (raw is! String) {
      throw StoryBuilderUnderstandingException(
        'AI Story Understanding $field must be a string.',
      );
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (trimmed.length > maxLength) {
      throw StoryBuilderUnderstandingException(
        'AI Story Understanding $field exceeds $maxLength characters.',
      );
    }
    return trimmed;
  }
}

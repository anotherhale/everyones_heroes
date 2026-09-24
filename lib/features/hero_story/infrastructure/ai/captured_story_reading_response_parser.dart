import 'dart:convert';

import 'package:everyonesheroes/features/hero_story/domain/services/captured_story_reading_port.dart';

/// Parses and validates EH-owned captured-story reading JSON (HS.12.3).
///
/// Rejects output that omits required fields, has invalid spans, or references
/// text outside the transcript. Psychological-claim field names are rejected.
abstract final class CapturedStoryReadingResponseParser {
  static const Set<String> forbiddenTopLevelKeys = {
    'personality',
    'attachmentStyle',
    'trauma',
    'mentalHealth',
    'diagnosis',
    'resilienceScore',
    'personalityTraits',
    'psychologicalProfile',
    'inferredMotivation',
    'inferredBehavioralTendencies',
    'motivation',
    'behavioralTendencies',
  };

  static CapturedStoryReadingDraft parse(
    String body, {
    required String transcriptText,
  }) {
    late final Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        throw const FormatException('Expected JSON object');
      }
      json = Map<String, dynamic>.from(decoded);
    } on FormatException catch (e) {
      throw CapturedStoryReadingException(
        'Malformed captured-story reading response: $e',
      );
    }

    for (final key in forbiddenTopLevelKeys) {
      if (json.containsKey(key)) {
        throw CapturedStoryReadingException(
          'Captured-story reading must not include psychological field "$key".',
        );
      }
    }

    final length = transcriptText.length;

    CapturedStoryReadingDraftElement requireElement(String name) {
      final raw = json[name];
      if (raw is! Map) {
        throw CapturedStoryReadingException(
          'Captured-story reading missing required field "$name".',
        );
      }
      return _parseElement(
        Map<String, dynamic>.from(raw),
        name: name,
        transcriptLength: length,
      );
    }

    final themesRaw = json['themes'];
    if (themesRaw is! List || themesRaw.isEmpty) {
      throw const CapturedStoryReadingException(
        'Captured-story reading requires a non-empty themes list.',
      );
    }

    final themes = <CapturedStoryReadingDraftTheme>[];
    for (var i = 0; i < themesRaw.length; i++) {
      final item = themesRaw[i];
      if (item is! Map) {
        throw CapturedStoryReadingException(
          'themes[$i] must be a JSON object.',
        );
      }
      themes.add(
        _parseTheme(
          Map<String, dynamic>.from(item),
          index: i,
          transcriptLength: length,
        ),
      );
    }

    return CapturedStoryReadingDraft(
      movement: requireElement('movement'),
      themes: themes,
      challenge: requireElement('challenge'),
      turningPoint: requireElement('turningPoint'),
      outcome: requireElement('outcome'),
      providerLabel: json['providerLabel'] as String?,
      processingVersion: json['processingVersion'] as String?,
    );
  }

  static CapturedStoryReadingDraftElement _parseElement(
    Map<String, dynamic> map, {
    required String name,
    required int transcriptLength,
  }) {
    final text = (map['text'] as String?)?.trim() ?? '';
    if (text.isEmpty) {
      throw CapturedStoryReadingException(
        'Captured-story reading "$name" text cannot be empty.',
      );
    }

    final span = map['sourceSpan'];
    if (span is! Map) {
      throw CapturedStoryReadingException(
        'Captured-story reading "$name" requires sourceSpan.',
      );
    }
    final start = span['startOffset'];
    final end = span['endOffset'];
    if (start is! int || end is! int) {
      throw CapturedStoryReadingException(
        'Captured-story reading "$name" sourceSpan requires integer offsets.',
      );
    }
    _assertSpan(name, start, end, transcriptLength);

    return CapturedStoryReadingDraftElement(
      text: text,
      startOffset: start,
      endOffset: end,
      startTimestampMs: span['startTimestampMs'] as int?,
      endTimestampMs: span['endTimestampMs'] as int?,
    );
  }

  static CapturedStoryReadingDraftTheme _parseTheme(
    Map<String, dynamic> map, {
    required int index,
    required int transcriptLength,
  }) {
    final label = (map['label'] as String?)?.trim() ?? '';
    if (label.isEmpty) {
      throw CapturedStoryReadingException(
        'themes[$index] label cannot be empty.',
      );
    }
    final span = map['sourceSpan'];
    if (span is! Map) {
      throw CapturedStoryReadingException(
        'themes[$index] requires sourceSpan.',
      );
    }
    final start = span['startOffset'];
    final end = span['endOffset'];
    if (start is! int || end is! int) {
      throw CapturedStoryReadingException(
        'themes[$index] sourceSpan requires integer offsets.',
      );
    }
    _assertSpan('themes[$index]', start, end, transcriptLength);

    return CapturedStoryReadingDraftTheme(
      label: label,
      startOffset: start,
      endOffset: end,
    );
  }

  static void _assertSpan(
    String name,
    int start,
    int end,
    int transcriptLength,
  ) {
    if (start < 0 || end < start || end > transcriptLength) {
      throw CapturedStoryReadingException(
        'Captured-story reading "$name" source span [$start, $end] is outside '
        'transcript (length $transcriptLength).',
      );
    }
  }
}

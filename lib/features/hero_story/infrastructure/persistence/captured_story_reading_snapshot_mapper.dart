import 'package:everyonesheroes/core/ids/captured_story_reading_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/captured_story_reading.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/grounded_story_element.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/source_span_reference.dart';

/// JSON snapshot mapper for durable [CapturedStoryReading] persistence.
abstract final class CapturedStoryReadingSnapshotMapper {
  static Map<String, dynamic> toJson(CapturedStoryReading reading) {
    return {
      'id': reading.id.value,
      'storyId': reading.storyId.value,
      'transcriptRepresentationId': reading.transcriptRepresentationId.value,
      'movement': _elementToJson(reading.movement),
      'themes': [
        for (final theme in reading.themes) _themeToJson(theme),
      ],
      'challenge': _elementToJson(reading.challenge),
      'turningPoint': _elementToJson(reading.turningPoint),
      'outcome': _elementToJson(reading.outcome),
      'createdAt': reading.createdAt.toIso8601String(),
      'providerLabel': reading.providerLabel,
      'processingVersion': reading.processingVersion,
    };
  }

  static CapturedStoryReading fromJson(Map<String, dynamic> json) {
    final themesRaw = json['themes'];
    if (themesRaw is! List) {
      throw const FormatException('CapturedStoryReading.themes must be a list.');
    }
    return CapturedStoryReading(
      id: CapturedStoryReadingId(json['id'] as String),
      storyId: StoryId(json['storyId'] as String),
      transcriptRepresentationId: StoryRepresentationId(
        json['transcriptRepresentationId'] as String,
      ),
      movement: _elementFromJson(
        Map<String, dynamic>.from(json['movement'] as Map),
      ),
      themes: [
        for (final raw in themesRaw)
          _themeFromJson(Map<String, dynamic>.from(raw as Map)),
      ],
      challenge: _elementFromJson(
        Map<String, dynamic>.from(json['challenge'] as Map),
      ),
      turningPoint: _elementFromJson(
        Map<String, dynamic>.from(json['turningPoint'] as Map),
      ),
      outcome: _elementFromJson(
        Map<String, dynamic>.from(json['outcome'] as Map),
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      providerLabel: json['providerLabel'] as String?,
      processingVersion: json['processingVersion'] as String? ??
          CapturedStoryReading.defaultProcessingVersion,
    );
  }

  static Map<String, dynamic> _elementToJson(GroundedStoryElement element) {
    return {
      'text': element.text,
      'sourceSpan': _spanToJson(element.sourceSpan),
    };
  }

  static GroundedStoryElement _elementFromJson(Map<String, dynamic> json) {
    return GroundedStoryElement(
      text: json['text'] as String,
      sourceSpan: _spanFromJson(
        Map<String, dynamic>.from(json['sourceSpan'] as Map),
      ),
    );
  }

  static Map<String, dynamic> _themeToJson(GroundedStoryTheme theme) {
    return {
      'label': theme.label,
      'sourceSpan': _spanToJson(theme.sourceSpan),
    };
  }

  static GroundedStoryTheme _themeFromJson(Map<String, dynamic> json) {
    return GroundedStoryTheme(
      label: json['label'] as String,
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

import 'package:flutter/foundation.dart';

import 'package:everyonesheroes/features/hero_story/domain/value_objects/captured_story_reading.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/grounded_story_element.dart';

/// Presentation model for a grounded captured-story reading (HS.12.3).
@immutable
final class CapturedStoryReadingViewData {
  const CapturedStoryReadingViewData({
    required this.movement,
    required this.themes,
    required this.challenge,
    required this.turningPoint,
    required this.outcome,
  });

  factory CapturedStoryReadingViewData.fromReading(CapturedStoryReading reading) {
    return CapturedStoryReadingViewData(
      movement: GroundedElementViewData.fromElement(reading.movement),
      themes: [
        for (final theme in reading.themes)
          GroundedThemeViewData.fromTheme(theme),
      ],
      challenge: GroundedElementViewData.fromElement(reading.challenge),
      turningPoint: GroundedElementViewData.fromElement(reading.turningPoint),
      outcome: GroundedElementViewData.fromElement(reading.outcome),
    );
  }

  final GroundedElementViewData movement;
  final List<GroundedThemeViewData> themes;
  final GroundedElementViewData challenge;
  final GroundedElementViewData turningPoint;
  final GroundedElementViewData outcome;
}

@immutable
final class GroundedElementViewData {
  const GroundedElementViewData({
    required this.text,
    required this.startOffset,
    required this.endOffset,
  });

  factory GroundedElementViewData.fromElement(GroundedStoryElement element) {
    return GroundedElementViewData(
      text: element.text,
      startOffset: element.sourceSpan.startOffset ?? 0,
      endOffset: element.sourceSpan.endOffset ?? 0,
    );
  }

  final String text;
  final int startOffset;
  final int endOffset;

  String get spanLabel => '[$startOffset–$endOffset]';
}

@immutable
final class GroundedThemeViewData {
  const GroundedThemeViewData({
    required this.label,
    required this.startOffset,
    required this.endOffset,
  });

  factory GroundedThemeViewData.fromTheme(GroundedStoryTheme theme) {
    return GroundedThemeViewData(
      label: theme.label,
      startOffset: theme.sourceSpan.startOffset ?? 0,
      endOffset: theme.sourceSpan.endOffset ?? 0,
    );
  }

  final String label;
  final int startOffset;
  final int endOffset;

  String get spanLabel => '[$startOffset–$endOffset]';
}

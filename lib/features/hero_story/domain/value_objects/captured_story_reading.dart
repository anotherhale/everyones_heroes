import 'package:everyonesheroes/core/ids/captured_story_reading_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/grounded_story_element.dart';

/// Grounded reading of one captured-story transcript (HS.12.3 / HS-ADR-072).
///
/// Derived presentation artifact. Not a [Story]. Not HS.4 [StoryUnderstanding].
/// Not SB.8 [StoryBuilderUnderstanding]. Does not rewrite the canonical Story.
///
/// Schema is narrative structure only — no personality, diagnosis, trauma,
/// attachment style, mental-health, or inferred motivation fields.
final class CapturedStoryReading extends ValueObject {
  CapturedStoryReading({
    required this.id,
    required this.storyId,
    required this.transcriptRepresentationId,
    required this.movement,
    required Iterable<GroundedStoryTheme> themes,
    required this.challenge,
    required this.turningPoint,
    required this.outcome,
    required this.createdAt,
    this.providerLabel,
    this.processingVersion = defaultProcessingVersion,
  }) : themes = List.unmodifiable(themes.toList()) {
    if (this.themes.isEmpty) {
      throw ArgumentError('CapturedStoryReading requires at least one theme.');
    }
    if (this.themes.length > maxThemes) {
      throw ArgumentError(
        'CapturedStoryReading may have at most $maxThemes themes.',
      );
    }
    final version = processingVersion.trim();
    if (version.isEmpty) {
      throw ArgumentError('processingVersion cannot be blank.');
    }
  }

  static const String defaultProcessingVersion = 'hs12.3.v1';
  static const int maxThemes = 8;

  final CapturedStoryReadingId id;
  final StoryId storyId;
  final StoryRepresentationId transcriptRepresentationId;
  final GroundedStoryElement movement;
  final List<GroundedStoryTheme> themes;
  final GroundedStoryElement challenge;
  final GroundedStoryElement turningPoint;
  final GroundedStoryElement outcome;
  final DateTime createdAt;
  final String? providerLabel;
  final String processingVersion;

  /// Validates that every element span lies within [transcriptText].
  ///
  /// Throws [ArgumentError] when any span is out of bounds. Callers that
  /// receive untrusted AI output must invoke this before persisting.
  void assertSpansWithinTranscript(String transcriptText) {
    final length = transcriptText.length;
    void check(String name, int? start, int? end) {
      if (start == null || end == null) {
        throw ArgumentError('$name is missing character offsets.');
      }
      if (start < 0 || end > length || start > end) {
        throw ArgumentError(
          '$name source span [$start, $end] is outside transcript '
          '(length $length).',
        );
      }
    }

    check(
      'movement',
      movement.sourceSpan.startOffset,
      movement.sourceSpan.endOffset,
    );
    for (var i = 0; i < themes.length; i++) {
      check(
        'themes[$i]',
        themes[i].sourceSpan.startOffset,
        themes[i].sourceSpan.endOffset,
      );
    }
    check(
      'challenge',
      challenge.sourceSpan.startOffset,
      challenge.sourceSpan.endOffset,
    );
    check(
      'turningPoint',
      turningPoint.sourceSpan.startOffset,
      turningPoint.sourceSpan.endOffset,
    );
    check(
      'outcome',
      outcome.sourceSpan.startOffset,
      outcome.sourceSpan.endOffset,
    );
  }

  @override
  List<Object?> get equalityProps => [
        id,
        storyId,
        transcriptRepresentationId,
        movement,
        themes,
        challenge,
        turningPoint,
        outcome,
        createdAt,
        providerLabel,
        processingVersion,
      ];
}

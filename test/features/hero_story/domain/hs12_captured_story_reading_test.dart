import 'package:everyonesheroes/core/ids/captured_story_reading_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/captured_story_reading.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/grounded_story_element.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/source_span_reference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final transcriptId = StoryRepresentationId('rep-transcript');
  final storyId = StoryId('story-1');

  SourceSpanReference span(int start, int end) {
    return SourceSpanReference(
      representationId: transcriptId,
      startOffset: start,
      endOffset: end,
    );
  }

  CapturedStoryReading buildReading({
    SourceSpanReference? challengeSpan,
  }) {
    return CapturedStoryReading(
      id: CapturedStoryReadingId('reading-1'),
      storyId: storyId,
      transcriptRepresentationId: transcriptId,
      movement: GroundedStoryElement(
        text: 'The story shifts from uncertainty to determination.',
        sourceSpan: span(0, 20),
      ),
      themes: [
        GroundedStoryTheme(label: 'courage', sourceSpan: span(10, 17)),
      ],
      challenge: GroundedStoryElement(
        text: 'Facing a hard moment.',
        sourceSpan: challengeSpan ?? span(20, 40),
      ),
      turningPoint: GroundedStoryElement(
        text: 'I knew I had to step forward.',
        sourceSpan: span(40, 60),
      ),
      outcome: GroundedStoryElement(
        text: 'And that is what I did.',
        sourceSpan: span(60, 80),
      ),
      createdAt: DateTime.utc(2026, 9, 24),
      providerLabel: 'test',
    );
  }

  test('requires grounded movement themes challenge turning point outcome', () {
    final reading = buildReading();
    expect(reading.movement.text, contains('shifts'));
    expect(reading.themes.single.label, 'courage');
    expect(reading.challenge.sourceSpan.startOffset, 20);
    expect(reading.turningPoint.sourceSpan.endOffset, 60);
    expect(reading.outcome.text, contains('what I did'));
  });

  test('rejects empty themes', () {
    expect(
      () => CapturedStoryReading(
        id: CapturedStoryReadingId('reading-1'),
        storyId: storyId,
        transcriptRepresentationId: transcriptId,
        movement: GroundedStoryElement(text: 'm', sourceSpan: span(0, 1)),
        themes: const [],
        challenge: GroundedStoryElement(text: 'c', sourceSpan: span(0, 1)),
        turningPoint: GroundedStoryElement(text: 't', sourceSpan: span(0, 1)),
        outcome: GroundedStoryElement(text: 'o', sourceSpan: span(0, 1)),
        createdAt: DateTime.utc(2026, 9, 24),
      ),
      throwsArgumentError,
    );
  });

  test('rejects element without character offsets', () {
    expect(
      () => GroundedStoryElement(
        text: 'ungrounded',
        sourceSpan: SourceSpanReference(representationId: transcriptId),
      ),
      throwsArgumentError,
    );
  });

  test('assertSpansWithinTranscript rejects out-of-bounds spans', () {
    final reading = buildReading(challengeSpan: span(0, 999));
    expect(
      () => reading.assertSpansWithinTranscript('short transcript'),
      throwsArgumentError,
    );
  });

  test('assertSpansWithinTranscript accepts in-bounds spans', () {
    final reading = buildReading();
    final transcript = List.filled(100, 'a').join();
    expect(() => reading.assertSpansWithinTranscript(transcript), returnsNormally);
  });
}

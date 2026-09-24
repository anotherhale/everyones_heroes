import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/captured_story_reading.dart';

/// Provider-independent captured-story reading boundary (HS.12.3).
///
/// Separate from [StoryTranscriptionPort], HS.4 [StoryUnderstandingPort], and
/// SB.8 [StoryBuilderUnderstandingPort].
abstract interface class CapturedStoryReadingPort {
  Future<CapturedStoryReadingDraft> generate(
    GenerateCapturedStoryReadingRequest request,
  );
}

/// EH-owned request: transcript text + identity, never OpenAI credentials.
final class GenerateCapturedStoryReadingRequest {
  const GenerateCapturedStoryReadingRequest({
    required this.storyId,
    required this.transcriptRepresentationId,
    required this.transcriptText,
    required this.language,
    required this.processingVersion,
  });

  final StoryId storyId;
  final StoryRepresentationId transcriptRepresentationId;
  final String transcriptText;
  final LanguageCode language;
  final String processingVersion;
}

/// Provider-agnostic draft mapped into [CapturedStoryReading].
final class CapturedStoryReadingDraft {
  const CapturedStoryReadingDraft({
    required this.movement,
    required this.themes,
    required this.challenge,
    required this.turningPoint,
    required this.outcome,
    this.providerLabel,
    this.processingVersion,
  });

  final CapturedStoryReadingDraftElement movement;
  final List<CapturedStoryReadingDraftTheme> themes;
  final CapturedStoryReadingDraftElement challenge;
  final CapturedStoryReadingDraftElement turningPoint;
  final CapturedStoryReadingDraftElement outcome;
  final String? providerLabel;
  final String? processingVersion;
}

final class CapturedStoryReadingDraftElement {
  const CapturedStoryReadingDraftElement({
    required this.text,
    required this.startOffset,
    required this.endOffset,
    this.startTimestampMs,
    this.endTimestampMs,
  });

  final String text;
  final int startOffset;
  final int endOffset;
  final int? startTimestampMs;
  final int? endTimestampMs;
}

final class CapturedStoryReadingDraftTheme {
  const CapturedStoryReadingDraftTheme({
    required this.label,
    required this.startOffset,
    required this.endOffset,
  });

  final String label;
  final int startOffset;
  final int endOffset;
}

final class CapturedStoryReadingException implements Exception {
  const CapturedStoryReadingException(this.message);

  final String message;

  @override
  String toString() => 'CapturedStoryReadingException: $message';
}

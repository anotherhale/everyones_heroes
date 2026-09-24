import 'package:everyonesheroes/features/hero_story/domain/services/captured_story_reading_port.dart';

/// Deterministic in-memory captured-story reading adapter (no network / no AI).
///
/// Builds grounded spans that always lie inside the supplied transcript text.
final class InMemoryCapturedStoryReadingAdapter
    implements CapturedStoryReadingPort {
  InMemoryCapturedStoryReadingAdapter({
    this.forcedFailureMessage,
  });

  /// When set, every call fails with this message.
  final String? forcedFailureMessage;

  @override
  Future<CapturedStoryReadingDraft> generate(
    GenerateCapturedStoryReadingRequest request,
  ) async {
    if (forcedFailureMessage != null) {
      throw CapturedStoryReadingException(forcedFailureMessage!);
    }

    final text = request.transcriptText;
    if (text.trim().isEmpty) {
      throw const CapturedStoryReadingException(
        'Transcript text cannot be empty for captured-story reading.',
      );
    }

    final length = text.length;
    int clampEnd(int end) => end > length ? length : end;

    // Partition the transcript into five contiguous grounded windows.
    final fifth = (length / 5).ceil().clamp(1, length);
    final movementEnd = clampEnd(fifth);
    final challengeEnd = clampEnd(fifth * 2);
    final turningEnd = clampEnd(fifth * 3);
    final outcomeEnd = clampEnd(fifth * 4);

    String slice(int start, int end) {
      final s = start.clamp(0, length);
      final e = end.clamp(s, length);
      final raw = text.substring(s, e).trim();
      if (raw.isNotEmpty) {
        return raw.length > 200 ? '${raw.substring(0, 200)}…' : raw;
      }
      return text.trim().length > 120
          ? '${text.trim().substring(0, 120)}…'
          : text.trim();
    }

    final themeStart = 0;
    final themeEnd = clampEnd(length < 24 ? length : 24);

    return CapturedStoryReadingDraft(
      movement: CapturedStoryReadingDraftElement(
        text:
            'The story moves through what the Hero described in their own words.',
        startOffset: 0,
        endOffset: movementEnd == 0 ? length : movementEnd,
      ),
      themes: [
        CapturedStoryReadingDraftTheme(
          label: _themeLabelFor(text),
          startOffset: themeStart,
          endOffset: themeEnd == 0 ? length : themeEnd,
        ),
      ],
      challenge: CapturedStoryReadingDraftElement(
        text: slice(movementEnd, challengeEnd),
        startOffset: movementEnd >= length ? 0 : movementEnd,
        endOffset: challengeEnd == 0 ? length : challengeEnd,
      ),
      turningPoint: CapturedStoryReadingDraftElement(
        text: slice(challengeEnd, turningEnd),
        startOffset: challengeEnd >= length ? 0 : challengeEnd,
        endOffset: turningEnd == 0 ? length : turningEnd,
      ),
      outcome: CapturedStoryReadingDraftElement(
        text: slice(turningEnd, outcomeEnd == 0 ? length : outcomeEnd),
        startOffset: turningEnd >= length ? 0 : turningEnd,
        endOffset: outcomeEnd == 0 ? length : outcomeEnd,
      ),
      providerLabel: 'in_memory',
      processingVersion: request.processingVersion,
    );
  }

  static String _themeLabelFor(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('courage')) return 'courage';
    if (lower.contains('loss')) return 'loss';
    if (lower.contains('military')) return 'service';
    if (lower.contains('persever')) return 'perseverance';
    return 'growth';
  }
}

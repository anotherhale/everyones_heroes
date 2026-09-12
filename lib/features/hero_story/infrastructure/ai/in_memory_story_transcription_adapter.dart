import 'dart:convert';

import 'package:everyonesheroes/features/hero_story/domain/enums/analysis_support_level.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_transcription_port.dart';

/// Deterministic in-memory transcription adapter (no network / no AI SDK).
final class InMemoryStoryTranscriptionAdapter
    implements StoryTranscriptionPort {
  InMemoryStoryTranscriptionAdapter({
    this.forcedFailureMessage,
    this.forcedEmptyText = false,
  });

  /// When set, every call fails with this message.
  final String? forcedFailureMessage;

  /// When true, returns empty transcript text (invalid).
  final bool forcedEmptyText;

  @override
  Future<StoryTranscriptionResult> transcribe(
    TranscribeStoryMediaRequest request,
  ) async {
    if (forcedFailureMessage != null) {
      throw StoryTranscriptionException(forcedFailureMessage!);
    }

    final bytes = request.mediaBytes;
    if (bytes == null || bytes.isEmpty) {
      throw const StoryTranscriptionException(
        'Media bytes are required for transcription.',
      );
    }

    final digest = base64Url.encode(bytes.take(32).toList());
    final text = forcedEmptyText
        ? ''
        : 'Transcript of story ${request.storyId.value} '
            'from representation ${request.sourceRepresentationId.value} '
            '[$digest]. The speaker discusses military service, courage, '
            'and starting over after loss.';

    if (text.trim().isEmpty) {
      throw const StoryTranscriptionException(
        'Transcript text cannot be empty.',
      );
    }

    return StoryTranscriptionResult(
      text: text,
      language: request.language,
      sourceMediaReference: request.mediaReference,
      providerLabel: 'in_memory',
      supportLevel: AnalysisSupportLevel.strong,
      opaqueProviderConfidence: 'deterministic',
    );
  }
}

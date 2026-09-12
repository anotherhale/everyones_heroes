import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/analysis_support_level.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';

/// Provider-independent transcription boundary (HS-ADR-024).
///
/// Prefer this over legacy [StoryCapturePort.requestTranscription].
abstract interface class StoryTranscriptionPort {
  Future<StoryTranscriptionResult> transcribe(TranscribeStoryMediaRequest request);
}

final class TranscribeStoryMediaRequest {
  const TranscribeStoryMediaRequest({
    required this.storyId,
    required this.sourceRepresentationId,
    required this.mediaReference,
    required this.language,
    required this.processingVersion,
    this.requestId,
    this.mediaBytes,
  });

  final StoryId storyId;
  final StoryRepresentationId sourceRepresentationId;
  final MediaReference mediaReference;
  final LanguageCode language;
  final String processingVersion;
  final String? requestId;
  final List<int>? mediaBytes;
}

final class StoryTranscriptionResult {
  const StoryTranscriptionResult({
    required this.text,
    required this.language,
    required this.sourceMediaReference,
    this.providerLabel,
    this.supportLevel,
    this.opaqueProviderConfidence,
  });

  final String text;
  final LanguageCode language;
  final MediaReference sourceMediaReference;
  final String? providerLabel;
  final AnalysisSupportLevel? supportLevel;
  final Object? opaqueProviderConfidence;
}

final class StoryTranscriptionException implements Exception {
  const StoryTranscriptionException(this.message);

  final String message;

  @override
  String toString() => 'StoryTranscriptionException: $message';
}

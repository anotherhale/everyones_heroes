import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_representation_format.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';

/// Legacy HS.1 capture/transcription stub (HS-ADR-020 / HS-ADR-024).
///
/// HS.3 capture orchestration uses StoryMediaStoragePort plus
/// CompleteStoryCaptureUseCase. Prefer those for new work.
///
/// requestTranscription remains unsupported. Real transcription belongs on
/// StoryTranscriptionPort (HS.4), not this legacy stub.
abstract interface class StoryCapturePort {
  Future<StoryCaptureResult> captureAudio({
    required StoryId storyId,
    required MediaReference mediaReference,
    required LanguageCode language,
  });

  Future<StoryCaptureResult> requestTranscription({
    required StoryId storyId,
    required MediaReference sourceAudio,
    required LanguageCode language,
  });
}

final class StoryCaptureResult {
  const StoryCaptureResult({
    required this.storyId,
    required this.status,
    this.format,
    this.message,
  });

  final StoryId storyId;
  final StoryCaptureStatus status;
  final StoryRepresentationFormat? format;
  final String? message;
}

enum StoryCaptureStatus {
  accepted,
  unsupported,
  failed,
}

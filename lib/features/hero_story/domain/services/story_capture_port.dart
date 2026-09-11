import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_representation_format.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';

/// Application-facing contract for future Story capture / processing.
///
/// HS.1 establishes the port only — no production AI or media pipeline.
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

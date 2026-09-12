import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_capture_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';

/// Stub capture port for HS.1. Accepts requests without running AI/media infra.
final class UnsupportedStoryCaptureAdapter implements StoryCapturePort {
  const UnsupportedStoryCaptureAdapter();

  @override
  Future<StoryCaptureResult> captureAudio({
    required StoryId storyId,
    required MediaReference mediaReference,
    required LanguageCode language,
  }) async {
    return StoryCaptureResult(
      storyId: storyId,
      status: StoryCaptureStatus.accepted,
      message:
          'Audio capture accepted for future processing; '
          'no production media pipeline in HS.1.',
    );
  }

  @override
  Future<StoryCaptureResult> requestTranscription({
    required StoryId storyId,
    required MediaReference sourceAudio,
    required LanguageCode language,
  }) async {
    return StoryCaptureResult(
      storyId: storyId,
      status: StoryCaptureStatus.unsupported,
      message:
          'Legacy StoryCapturePort transcription is unsupported; '
          'use StoryTranscriptionPort (HS.4 / HS-ADR-024).',
    );
  }
}

import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';

/// Owner-initiated transcription start / retry (HS.11 / HS-ADR-069).
final class StartOwnedStoryTranscriptionRequest {
  const StartOwnedStoryTranscriptionRequest({
    required this.storyId,
    required this.ownerHeroId,
    this.sourceRepresentationId,
    this.requestId,
    this.transcriptRepresentationId,
    this.processingVersion = 'hs4-v1',
    this.occurredAt,
    this.isRetry = false,
  });

  final StoryId storyId;
  final HeroId ownerHeroId;

  /// Defaults to the Story's primary original audio representation.
  final StoryRepresentationId? sourceRepresentationId;

  /// When omitted, a new request id is generated.
  final String? requestId;

  /// When omitted, a new transcript representation id is generated (or reused
  /// from a prior failed job that never persisted a representation).
  final StoryRepresentationId? transcriptRepresentationId;

  final String processingVersion;
  final DateTime? occurredAt;

  /// When true, allows restarting from [StoryTranscriptionJobStatus.failed].
  final bool isRetry;
}

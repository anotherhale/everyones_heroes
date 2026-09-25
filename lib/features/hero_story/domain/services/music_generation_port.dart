import 'dart:typed_data';

import 'package:everyonesheroes/core/ids/story_experience_plan_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';

/// Provider-independent music-generation boundary (lab plan: MusicGenerationPort).
///
/// Produces derived [MusicRendering] bytes. Domain must not know Stable Audio,
/// Mubert, or other vendors. Strategy A: one instrumental bed.
abstract interface class MusicGenerationPort {
  Future<MusicGenerationDraft> generate(MusicGenerationRequest request);
}

/// Structured request derived from experience intent — not free-form user text.
final class MusicGenerationRequest {
  const MusicGenerationRequest({
    required this.storyId,
    required this.experiencePlanId,
    required this.experiencePlanProcessingVersion,
    required this.prompt,
    required this.targetDurationSeconds,
    this.mood,
    this.energy,
    this.style,
    this.instrumentalPreferred = true,
    this.intensityCurveHints = const [],
    this.processingVersion,
    this.providerHint,
    this.modelHint,
    this.experimentId,
    this.requestId,
  });

  final StoryId storyId;
  final StoryExperiencePlanId experiencePlanId;
  final String experiencePlanProcessingVersion;
  final String prompt;
  final int targetDurationSeconds;
  final String? mood;
  final String? energy;
  final String? style;
  final bool instrumentalPreferred;
  final List<String> intensityCurveHints;
  final String? processingVersion;
  final String? providerHint;
  final String? modelHint;
  final String? experimentId;
  final String? requestId;
}

/// EH-owned draft mapped into a persisted MusicRendering by the use case.
final class MusicGenerationDraft {
  const MusicGenerationDraft({
    required this.audioBytes,
    required this.contentType,
    this.duration,
    this.providerLabel,
    this.modelLabel,
    this.generationId,
    this.promptUsed,
    this.processingVersion,
    this.instrumental = true,
  });

  final Uint8List audioBytes;
  final String contentType;
  final Duration? duration;
  final String? providerLabel;
  final String? modelLabel;
  final String? generationId;
  final String? promptUsed;
  final String? processingVersion;
  final bool instrumental;
}

final class MusicGenerationException implements Exception {
  const MusicGenerationException(this.message);

  final String message;

  @override
  String toString() => 'MusicGenerationException: $message';
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:everyonesheroes/features/hero_story/domain/enums/voice_rendering_mode.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/voice_rendering_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_voice_rendering.dart';

/// Deterministic [VoiceRenderingPort] for tests and local development.
///
/// Produces a complete-file synthetic narration artifact without calling any
/// commercial TTS vendor. Voice cloning is rejected.
final class InMemoryVoiceRenderingAdapter implements VoiceRenderingPort {
  InMemoryVoiceRenderingAdapter({
    this.audioBytes,
    this.contentType = 'audio/mpeg',
    this.failWith,
    this.delay = Duration.zero,
  });

  /// Optional fixed audio payload. Defaults to a tiny non-empty MP3-like stub.
  Uint8List? audioBytes;
  String contentType;
  VoiceRenderingException? failWith;
  Duration delay;

  int callCount = 0;
  VoiceRenderingRequest? lastRequest;

  @override
  Future<VoiceRenderingDraft> render(VoiceRenderingRequest request) async {
    callCount += 1;
    lastRequest = request;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (failWith != null) {
      throw failWith!;
    }
    if (request.renderingMode != VoiceRenderingMode.syntheticNarration) {
      throw VoiceRenderingException(
        'Unsupported voice rendering mode: ${request.renderingMode.name}',
      );
    }
    final text = request.sourceText.trim();
    if (text.isEmpty) {
      throw const VoiceRenderingException(
        'sourceText is required for voice rendering.',
      );
    }

    final bytes = audioBytes ??
        Uint8List.fromList(
          utf8.encode(
            'FAKE-TTS:${request.storyId.value}:'
            '${request.language.value}:${text.hashCode}',
          ),
        );
    final providerLabel = request.providerHint?.trim().isNotEmpty == true
        ? 'in_memory_${request.providerHint!.trim()}'
        : 'in_memory_voice_rendering';
    final modelLabel = request.modelHint?.trim().isNotEmpty == true
        ? request.modelHint!.trim()
        : 'fake-tts';
    return VoiceRenderingDraft(
      audioBytes: bytes,
      contentType: contentType,
      language: request.language,
      renderingMode: VoiceRenderingMode.syntheticNarration,
      providerLabel: providerLabel,
      modelLabel: modelLabel,
      processingVersion: request.processingVersion ??
          StoryVoiceRendering.defaultProcessingVersion,
    );
  }
}

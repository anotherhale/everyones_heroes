import 'dart:convert';
import 'dart:typed_data';

import 'package:everyonesheroes/features/hero_story/domain/services/music_generation_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/music_rendering.dart';

/// Deterministic [MusicGenerationPort] for tests and local development.
final class InMemoryMusicGenerationAdapter implements MusicGenerationPort {
  InMemoryMusicGenerationAdapter({
    this.audioBytes,
    this.contentType = 'audio/mpeg',
    this.failWith,
    this.delay = Duration.zero,
  });

  Uint8List? audioBytes;
  String contentType;
  MusicGenerationException? failWith;
  Duration delay;

  int callCount = 0;
  MusicGenerationRequest? lastRequest;

  @override
  Future<MusicGenerationDraft> generate(MusicGenerationRequest request) async {
    callCount += 1;
    lastRequest = request;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (failWith != null) {
      throw failWith!;
    }

    final prompt = request.prompt.trim();
    if (prompt.isEmpty) {
      throw const MusicGenerationException('Music prompt cannot be empty.');
    }
    if (request.instrumentalPreferred) {
      final lower = prompt.toLowerCase();
      if (!lower.contains('instrumental') &&
          !lower.contains('no vocals') &&
          !lower.contains('no lyrics')) {
        throw const MusicGenerationException(
          'Instrumental constraint missing from music prompt.',
        );
      }
    }
    if (request.targetDurationSeconds <= 0) {
      throw const MusicGenerationException(
        'targetDurationSeconds must be positive.',
      );
    }

    final bytes = audioBytes ??
        Uint8List.fromList(
          utf8.encode(
            'FAKE-MUSIC:${request.storyId.value}:${prompt.hashCode}:'
            '${request.targetDurationSeconds}',
          ),
        );

    return MusicGenerationDraft(
      audioBytes: bytes,
      contentType: contentType,
      duration: Duration(seconds: request.targetDurationSeconds),
      providerLabel: 'in_memory_music_generation',
      modelLabel: 'fake-stable-audio',
      generationId: 'fake-gen-${request.storyId.value}',
      promptUsed: prompt,
      processingVersion: request.processingVersion ??
          MusicRendering.defaultProcessingVersion,
      instrumental: true,
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/domain/services/story_transcription_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_transcription_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/proxy_story_transcription_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/story_transcription_config.dart';

/// Default: development [InMemoryStoryTranscriptionAdapter].
///
/// Production composition overrides with [ProxyStoryTranscriptionAdapter] when
/// `EH_AI_PROXY_URL` is configured (HS-ADR-067).
final storyTranscriptionPortProvider = Provider<StoryTranscriptionPort>((ref) {
  final mode = StoryTranscriptionConfig.resolveMode();
  if (mode == StoryTranscriptionMode.proxy) {
    final baseUrl = StoryTranscriptionConfig.resolveProxyBaseUrl();
    if (baseUrl == null) {
      throw StateError(
        'EH_TRANSCRIPTION_MODE=proxy requires EH_AI_PROXY_URL.',
      );
    }
    final adapter = ProxyStoryTranscriptionAdapter(
      baseUrl: baseUrl,
      authToken: StoryTranscriptionConfig.resolveAuthToken(),
    );
    ref.onDispose(adapter.dispose);
    return adapter;
  }
  return InMemoryStoryTranscriptionAdapter();
});

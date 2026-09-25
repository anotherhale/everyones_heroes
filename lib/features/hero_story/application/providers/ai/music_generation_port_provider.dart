import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/domain/services/music_generation_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/music_generation_config.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/proxy_music_generation_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/story_transcription_config.dart';

/// Default: development in-memory adapter.
///
/// Proxy mode when `EH_AI_PROXY_URL` / `EH_TRANSCRIPTION_MODE=proxy`.
final musicGenerationPortProvider = Provider<MusicGenerationPort>((ref) {
  final mode = MusicGenerationConfig.resolveMode();
  if (mode == StoryTranscriptionMode.proxy) {
    final baseUrl = MusicGenerationConfig.resolveProxyBaseUrl();
    if (baseUrl == null) {
      throw StateError(
        'EH_TRANSCRIPTION_MODE=proxy requires EH_AI_PROXY_URL.',
      );
    }
    final adapter = ProxyMusicGenerationAdapter(
      baseUrl: baseUrl,
      authToken: MusicGenerationConfig.resolveAuthToken(),
    );
    ref.onDispose(adapter.dispose);
    return adapter;
  }
  return MusicGenerationConfig.createDevelopmentAdapter();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/domain/services/voice_rendering_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/proxy_voice_rendering_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/story_transcription_config.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/voice_rendering_config.dart';

/// Default: development [InMemoryVoiceRenderingAdapter].
///
/// Production uses [ProxyVoiceRenderingAdapter] when `EH_AI_PROXY_URL` /
/// `EH_TRANSCRIPTION_MODE=proxy` is configured (same defines as transcription).
final voiceRenderingPortProvider = Provider<VoiceRenderingPort>((ref) {
  final mode = VoiceRenderingConfig.resolveMode();
  if (mode == StoryTranscriptionMode.proxy) {
    final baseUrl = VoiceRenderingConfig.resolveProxyBaseUrl();
    if (baseUrl == null) {
      throw StateError(
        'EH_TRANSCRIPTION_MODE=proxy requires EH_AI_PROXY_URL.',
      );
    }
    final adapter = ProxyVoiceRenderingAdapter(
      baseUrl: baseUrl,
      authToken: VoiceRenderingConfig.resolveAuthToken(),
    );
    ref.onDispose(adapter.dispose);
    return adapter;
  }
  return VoiceRenderingConfig.createDevelopmentAdapter();
});

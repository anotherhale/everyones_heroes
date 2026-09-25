import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/application/lab/creative_direction_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/creative_direction_config.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/proxy_creative_direction_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/story_transcription_config.dart';

/// Default: development in-memory adapter.
///
/// Proxy mode when `EH_AI_PROXY_URL` / `EH_TRANSCRIPTION_MODE=proxy`.
final creativeDirectionPortProvider = Provider<CreativeDirectionPort>((ref) {
  final mode = CreativeDirectionConfig.resolveMode();
  if (mode == StoryTranscriptionMode.proxy) {
    final baseUrl = CreativeDirectionConfig.resolveProxyBaseUrl();
    if (baseUrl == null) {
      throw StateError(
        'EH_TRANSCRIPTION_MODE=proxy requires EH_AI_PROXY_URL.',
      );
    }
    final adapter = ProxyCreativeDirectionAdapter(
      baseUrl: baseUrl,
      authToken: CreativeDirectionConfig.resolveAuthToken(),
    );
    ref.onDispose(adapter.dispose);
    return adapter;
  }
  return CreativeDirectionConfig.createDevelopmentAdapter();
});

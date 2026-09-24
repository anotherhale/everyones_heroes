import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/domain/services/captured_story_reading_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/captured_story_reading_config.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/proxy_captured_story_reading_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/story_transcription_config.dart';

/// Default: development [InMemoryCapturedStoryReadingAdapter].
///
/// Production uses [ProxyCapturedStoryReadingAdapter] when `EH_AI_PROXY_URL` /
/// `EH_TRANSCRIPTION_MODE=proxy` is configured (same defines as transcription).
final capturedStoryReadingPortProvider =
    Provider<CapturedStoryReadingPort>((ref) {
  final mode = CapturedStoryReadingConfig.resolveMode();
  if (mode == StoryTranscriptionMode.proxy) {
    final baseUrl = CapturedStoryReadingConfig.resolveProxyBaseUrl();
    if (baseUrl == null) {
      throw StateError(
        'EH_TRANSCRIPTION_MODE=proxy requires EH_AI_PROXY_URL.',
      );
    }
    final adapter = ProxyCapturedStoryReadingAdapter(
      baseUrl: baseUrl,
      authToken: CapturedStoryReadingConfig.resolveAuthToken(),
    );
    ref.onDispose(adapter.dispose);
    return adapter;
  }
  return CapturedStoryReadingConfig.createDevelopmentAdapter();
});

import 'package:everyonesheroes/features/hero_story/domain/services/story_authoring_transport.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_proposal_authoring_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/story_transcription_config.dart';

/// Resolves Story Proposal AI shaping mode from compile-time configuration.
///
/// Reuses [EH_AI_PROXY_URL] / [EH_AI_PROXY_AUTH_TOKEN] — no second proxy URL.
/// Optional: `--dart-define=EH_STORY_AUTHORING_MODE=proxy|development`.
///
/// Distinct from HS.5 [StoryAuthoringPort] / [InMemoryStoryAuthoringAdapter].
enum StoryAuthoringMode {
  development,
  proxy,
}

abstract final class StoryAuthoringConfig {
  static const String modeDefine = String.fromEnvironment(
    'EH_STORY_AUTHORING_MODE',
    defaultValue: '',
  );

  static StoryAuthoringMode resolveMode() {
    final explicit = modeDefine.trim().toLowerCase();
    if (explicit == 'proxy') {
      return StoryAuthoringMode.proxy;
    }
    if (explicit == 'development' || explicit == 'dev') {
      return StoryAuthoringMode.development;
    }
    if (StoryTranscriptionConfig.proxyUrlDefine.trim().isNotEmpty) {
      return StoryAuthoringMode.proxy;
    }
    return StoryAuthoringMode.development;
  }

  static Uri? resolveProxyBaseUrl() =>
      StoryTranscriptionConfig.resolveProxyBaseUrl();

  static String? resolveAuthToken() =>
      StoryTranscriptionConfig.resolveAuthToken();

  static StoryAuthoringTransport createDevelopmentAdapter() {
    return InMemoryStoryProposalAuthoringAdapter();
  }
}

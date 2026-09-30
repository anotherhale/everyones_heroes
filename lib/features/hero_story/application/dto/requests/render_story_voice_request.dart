import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/voice_rendering_mode.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_voice_rendering.dart';

/// Application request to render a derived Story voice presentation (HS.12.6).
final class RenderStoryVoiceAppRequest {
  const RenderStoryVoiceAppRequest({
    required this.storyId,
    required this.ownerHeroId,
    this.renderingMode = VoiceRenderingMode.syntheticNarration,
    this.forceRegenerate = false,
    this.processingVersion = StoryVoiceRendering.defaultProcessingVersion,
    this.providerHint,
    this.modelHint,
    this.occurredAt,
  });

  final StoryId storyId;
  final HeroId ownerHeroId;
  final VoiceRenderingMode renderingMode;

  /// When false, returns an existing artifact for the same plan version.
  final bool forceRegenerate;
  final String processingVersion;

  /// Optional opaque infrastructure provider selection hint (not a vendor SDK).
  final String? providerHint;

  /// Optional opaque infrastructure model selection hint.
  final String? modelHint;
  final DateTime? occurredAt;
}

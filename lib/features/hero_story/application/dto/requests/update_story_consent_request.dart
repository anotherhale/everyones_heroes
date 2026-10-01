import 'package:everyonesheroes/core/ids/story_id.dart';

final class UpdateStoryConsentRequest {
  const UpdateStoryConsentRequest({
    required this.storyId,
    this.grantProcessing = false,
    this.grantPublication = false,
    this.grantAiTransformation = false,
    this.grantVoiceRendering = false,
    this.grantMusicGeneration = false,
    this.grantVoiceCloning = false,
    this.denyVoiceCloning = false,
    this.revokeProcessing = false,
    this.revokePublication = false,
    this.revokeAiTransformation = false,
    this.revokeVoiceRendering = false,
    this.revokeMusicGeneration = false,
    this.revokeVoiceCloning = false,
    this.at,
  });

  final StoryId storyId;
  final bool grantProcessing;
  final bool grantPublication;
  final bool grantAiTransformation;
  final bool grantVoiceRendering;
  final bool grantMusicGeneration;

  /// Story-level voice cloning authorization (HS.12.10).
  /// Independent of [grantVoiceRendering] (synthetic narration only).
  final bool grantVoiceCloning;

  /// Explicit Story-level voice cloning denial (HS.12.10).
  /// Always wins over profile-level cloning authorization.
  final bool denyVoiceCloning;

  final bool revokeProcessing;
  final bool revokePublication;
  final bool revokeAiTransformation;
  final bool revokeVoiceRendering;
  final bool revokeMusicGeneration;

  /// Clears Story-level cloning grant and denial back to not-granted.
  final bool revokeVoiceCloning;

  final DateTime? at;
}

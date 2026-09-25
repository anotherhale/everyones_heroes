import 'package:everyonesheroes/core/ids/story_id.dart';

final class UpdateStoryConsentRequest {
  const UpdateStoryConsentRequest({
    required this.storyId,
    this.grantProcessing = false,
    this.grantPublication = false,
    this.grantAiTransformation = false,
    this.grantVoiceRendering = false,
    this.grantMusicGeneration = false,
    this.revokeProcessing = false,
    this.revokePublication = false,
    this.revokeAiTransformation = false,
    this.revokeVoiceRendering = false,
    this.revokeMusicGeneration = false,
    this.at,
  });

  final StoryId storyId;
  final bool grantProcessing;
  final bool grantPublication;
  final bool grantAiTransformation;
  final bool grantVoiceRendering;
  final bool grantMusicGeneration;
  final bool revokeProcessing;
  final bool revokePublication;
  final bool revokeAiTransformation;
  final bool revokeVoiceRendering;
  final bool revokeMusicGeneration;
  final DateTime? at;
}

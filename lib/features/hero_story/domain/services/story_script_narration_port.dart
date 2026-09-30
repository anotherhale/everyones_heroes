import 'package:everyonesheroes/core/ids/story_builder_script_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';

/// Future seam: narrate an **approved** Story Builder script (SB.8).
///
/// Downstream adapters may include Hero recording, voice cloning, or generic
/// TTS. All must consume approved script content — never the raw session and
/// never invent narrative. No provider is wired in SB.8.
abstract interface class StoryScriptNarrationPort {
  Future<StoryScriptNarrationResult> narrate(
    StoryScriptNarrationRequest request,
  );
}

final class StoryScriptNarrationRequest {
  const StoryScriptNarrationRequest({
    required this.scriptId,
    required this.approvedContent,
    required this.language,
    this.storyId,
  });

  final StoryBuilderScriptId scriptId;
  final String approvedContent;
  final LanguageCode language;
  final StoryId? storyId;
}

final class StoryScriptNarrationResult {
  const StoryScriptNarrationResult({
    required this.mediaUri,
    this.contentType,
    this.providerLabel,
  });

  final String mediaUri;
  final String? contentType;
  final String? providerLabel;
}

/// Placeholder until a narration adapter is authorized.
final class UnsupportedStoryScriptNarrationPort
    implements StoryScriptNarrationPort {
  const UnsupportedStoryScriptNarrationPort();

  @override
  Future<StoryScriptNarrationResult> narrate(
    StoryScriptNarrationRequest request,
  ) {
    throw UnsupportedError(
      'Story script narration is not implemented yet. '
      'Approved scripts remain available for future Hero recording / '
      'voice-clone / TTS adapters.',
    );
  }
}

import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/application/playback/story_experience_demo_stem.dart';

/// Closed intensity labels aligned with the existing EH narrative pacing model.
enum MusicIntensityLabel {
  quiet,
  tension,
  build,
  expansive,
  resolve,
}

/// Structured creative-direction output for laboratory presentation (not Story).
///
/// Grounded exclusively in StoryExperiencePlan / reading / timeline inputs.
/// Must never contain psychological, personality, or diagnostic fields.
final class PresentationCreativeDirection extends ValueObject {
  PresentationCreativeDirection({
    required String narrationEmphasis,
    required String pacingGuidance,
    required this.intensityProgression,
    required String musicPromptBrief,
    this.pauses = const [],
    this.transitionNotes = const [],
    String? providerLabel,
    String? modelLabel,
    String processingVersion = defaultProcessingVersion,
  })  : narrationEmphasis = narrationEmphasis.trim(),
        pacingGuidance = pacingGuidance.trim(),
        musicPromptBrief = musicPromptBrief.trim(),
        providerLabel = _trimOrNull(providerLabel),
        modelLabel = _trimOrNull(modelLabel),
        processingVersion = processingVersion.trim() {
    if (this.narrationEmphasis.isEmpty) {
      throw ArgumentError('narrationEmphasis cannot be blank.');
    }
    if (this.pacingGuidance.isEmpty) {
      throw ArgumentError('pacingGuidance cannot be blank.');
    }
    if (this.musicPromptBrief.isEmpty) {
      throw ArgumentError('musicPromptBrief cannot be blank.');
    }
    if (intensityProgression.isEmpty) {
      throw ArgumentError('intensityProgression cannot be empty.');
    }
    if (this.processingVersion.isEmpty) {
      throw ArgumentError('processingVersion cannot be blank.');
    }
    final briefLower = this.musicPromptBrief.toLowerCase();
    if (!briefLower.contains('instrumental') &&
        !briefLower.contains('no vocals') &&
        !briefLower.contains('no lyrics')) {
      throw ArgumentError(
        'musicPromptBrief must require instrumental / no vocals / no lyrics.',
      );
    }
  }

  static const String defaultProcessingVersion = 'exp-a.creative.v1';

  final String narrationEmphasis;
  final String pacingGuidance;
  final List<String> pauses;
  final List<CreativeIntensityStep> intensityProgression;
  final String musicPromptBrief;
  final List<String> transitionNotes;
  final String? providerLabel;
  final String? modelLabel;
  final String processingVersion;

  static String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  @override
  List<Object?> get equalityProps => [
        narrationEmphasis,
        pacingGuidance,
        pauses,
        intensityProgression,
        musicPromptBrief,
        transitionNotes,
        providerLabel,
        modelLabel,
        processingVersion,
      ];
}

/// One step in the creative intensity / music guidance progression.
final class CreativeIntensityStep extends ValueObject {
  CreativeIntensityStep({
    required this.purpose,
    required this.intensity,
    String? guidance,
  }) : guidance = _trimOrNull(guidance);

  final StoryExperiencePresentationPurpose purpose;
  final MusicIntensityLabel intensity;
  final String? guidance;

  static String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  @override
  List<Object?> get equalityProps => [purpose, intensity, guidance];
}

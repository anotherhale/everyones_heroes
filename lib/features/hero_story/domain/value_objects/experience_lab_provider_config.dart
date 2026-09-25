import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/experience_lab_experiment.dart';

/// Opaque provider selection for a laboratory run.
///
/// Vendor names appear only as opaque labels — domain logic must not branch
/// on specific commercial SDKs. Credentials never live here.
final class ExperienceLabProviderConfig extends ValueObject {
  ExperienceLabProviderConfig({
    required this.experiment,
    required String creativeProvider,
    required String creativeModel,
    required String voiceProvider,
    required String voiceModel,
    required String musicProvider,
    required String musicModel,
    String creativePromptVersion = 'exp-a.creative.v1',
    String voicePromptVersion = 'hs12.6.v1',
    String musicPromptVersion = 'exp-a.music.v1',
  })  : creativeProvider = creativeProvider.trim(),
        creativeModel = creativeModel.trim(),
        voiceProvider = voiceProvider.trim(),
        voiceModel = voiceModel.trim(),
        musicProvider = musicProvider.trim(),
        musicModel = musicModel.trim(),
        creativePromptVersion = creativePromptVersion.trim(),
        voicePromptVersion = voicePromptVersion.trim(),
        musicPromptVersion = musicPromptVersion.trim() {
    if (this.creativeProvider.isEmpty ||
        this.creativeModel.isEmpty ||
        this.voiceProvider.isEmpty ||
        this.voiceModel.isEmpty ||
        this.musicProvider.isEmpty ||
        this.musicModel.isEmpty) {
      throw ArgumentError('Provider/model labels cannot be blank.');
    }
  }

  /// Experiment A defaults (OpenAI creative + OpenAI TTS + Stable Audio 3.0).
  factory ExperienceLabProviderConfig.experimentA() {
    return ExperienceLabProviderConfig(
      experiment: ExperienceLabExperiment.experimentA,
      creativeProvider: 'openai',
      creativeModel: 'gpt-4o-mini',
      voiceProvider: 'openai',
      voiceModel: 'tts-1',
      musicProvider: 'stable_audio',
      musicModel: 'stable-audio-3',
    );
  }

  final ExperienceLabExperiment experiment;
  final String creativeProvider;
  final String creativeModel;
  final String voiceProvider;
  final String voiceModel;
  final String musicProvider;
  final String musicModel;
  final String creativePromptVersion;
  final String voicePromptVersion;
  final String musicPromptVersion;

  /// Stable fingerprint for cache / reuse decisions (no secrets).
  String get fingerprint => [
        experiment.name,
        creativeProvider,
        creativeModel,
        creativePromptVersion,
        voiceProvider,
        voiceModel,
        voicePromptVersion,
        musicProvider,
        musicModel,
        musicPromptVersion,
      ].join('|');

  @override
  List<Object?> get equalityProps => [
        experiment,
        creativeProvider,
        creativeModel,
        voiceProvider,
        voiceModel,
        musicProvider,
        musicModel,
        creativePromptVersion,
        voicePromptVersion,
        musicPromptVersion,
      ];
}

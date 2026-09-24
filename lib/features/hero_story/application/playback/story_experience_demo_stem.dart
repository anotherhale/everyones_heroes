/// Closed demo-stem vocabulary for HS.12.5 experience playback.
///
/// The Story Experience Plan never names audio files. The player maps
/// [StoryExperiencePresentationPurpose] → [StoryExperienceDemoStem] → a
/// bundled asset path. Replace assets later without changing the plan schema.
enum StoryExperienceDemoStem {
  quiet,
  tension,
  build,
  expansive,
  resolve,
}

/// Presentation purposes derived from a persisted [StoryExperiencePlan]
/// sequence (player-layer vocabulary — not stored on the plan).
enum StoryExperiencePresentationPurpose {
  opening,
  challenge,
  uncertainty,
  turningPoint,
  decision,
  resolution,
  closing,
}

/// Deterministic purpose → stem mapping (HS.12.5 / HS-ADR-075).
StoryExperienceDemoStem? stemForPresentationPurpose(
  StoryExperiencePresentationPurpose purpose,
) {
  return switch (purpose) {
    StoryExperiencePresentationPurpose.opening => StoryExperienceDemoStem.quiet,
    StoryExperiencePresentationPurpose.challenge =>
      StoryExperienceDemoStem.tension,
    StoryExperiencePresentationPurpose.uncertainty =>
      StoryExperienceDemoStem.quiet,
    StoryExperiencePresentationPurpose.turningPoint => null, // intentional silence
    StoryExperiencePresentationPurpose.decision => StoryExperienceDemoStem.build,
    StoryExperiencePresentationPurpose.resolution =>
      StoryExperienceDemoStem.expansive,
    StoryExperiencePresentationPurpose.closing =>
      StoryExperienceDemoStem.resolve,
  };
}

/// Bundled asset paths for demo stems.
///
/// Location: `assets/audio/demo_stems/{stem}.wav`
final class StoryExperienceDemoStemAssets {
  const StoryExperienceDemoStemAssets._();

  static const String directory = 'assets/audio/demo_stems';

  static String assetPath(StoryExperienceDemoStem stem) {
    return '$directory/${stem.name}.wav';
  }

  static const List<String> allAssetPaths = [
    '$directory/quiet.wav',
    '$directory/tension.wav',
    '$directory/build.wav',
    '$directory/expansive.wav',
    '$directory/resolve.wav',
  ];
}

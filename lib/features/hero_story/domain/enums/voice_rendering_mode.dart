/// How a derived Story voice presentation was (or will be) rendered (HS.12.6).
///
/// These modes are intentionally distinct. HS.12.6 v1 supports only
/// [syntheticNarration] (ordinary TTS). Hero-owned voice transformation and
/// voice cloning require their own consent and provider capability — they must
/// not be silently treated as equivalent to synthetic narration.
enum VoiceRenderingMode {
  /// Ordinary synthetic narration (provider TTS). Not the Hero's voice.
  syntheticNarration,

  /// Future: transformation using the Hero's own recorded voice (not cloning).
  heroVoiceTransformation,

  /// Future: voice cloning. Requires explicit cloning consent and capability.
  voiceClone,
}

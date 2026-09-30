/// Infrastructure-only TTS provider abstraction (HS.12.7).
///
/// Lives exclusively inside `services/ai_proxy`. Must never be imported by
/// Flutter, domain, or application layers. Provider selection is resolved from
/// env / opaque hints — not from Story or VoiceRenderingPort contracts.
abstract interface class TtsProvider {
  /// Opaque provider key used for provenance labels (e.g. `openai`, `qwen3`).
  String get providerKey;

  /// Synthesize complete-file audio for [text]. No streaming.
  Future<TtsSynthesisResult> synthesize(TtsSynthesisRequest request);
}

/// Minimum synthesis inputs for a complete-file narration.
final class TtsSynthesisRequest {
  const TtsSynthesisRequest({
    required this.text,
    required this.language,
    this.modelHint,
  });

  final String text;

  /// BCP 47 language tag already validated by the EH HTTP handler.
  final String language;

  /// Optional opaque model override from lab hints / config.
  final String? modelHint;
}

final class TtsSynthesisResult {
  const TtsSynthesisResult({
    required this.audioBytes,
    required this.contentType,
    required this.modelLabel,
    this.providerLabelSuffix,
  });

  final List<int> audioBytes;
  final String contentType;
  final String modelLabel;

  /// Optional extra provenance fragment (e.g. voice name). Unused by EH domain.
  final String? providerLabelSuffix;
}

final class TtsProviderException implements Exception {
  const TtsProviderException(this.message);

  final String message;

  @override
  String toString() => 'TtsProviderException: $message';
}

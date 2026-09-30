import 'package:ai_proxy/src/openai_speech_client.dart';
import 'package:ai_proxy/src/tts/tts_provider.dart';

/// OpenAI TTS adapter behind the proxy-only [TtsProvider] seam (HS.12.7).
///
/// Wraps the existing [OpenAiSpeechClient]. Does not perform voice cloning.
final class OpenAiTtsProvider implements TtsProvider {
  OpenAiTtsProvider({required OpenAiSpeechClient this._client});

  final OpenAiSpeechClient _client;

  @override
  String get providerKey => 'openai';

  @override
  Future<TtsSynthesisResult> synthesize(TtsSynthesisRequest request) async {
    try {
      final result = await _client.synthesize(text: request.text);
      return TtsSynthesisResult(
        audioBytes: result.audioBytes,
        contentType: result.contentType,
        modelLabel: request.modelHint?.trim().isNotEmpty == true
            ? request.modelHint!.trim()
            : result.model,
        providerLabelSuffix: result.voice,
      );
    } on OpenAiSpeechException catch (e) {
      throw TtsProviderException(e.message);
    }
  }
}

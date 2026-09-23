import 'package:eh_platform/src/ai/ai_completion_request.dart';
import 'package:eh_platform/src/ai/ai_completion_result.dart';
import 'package:eh_platform/src/ai/ai_orchestration_port.dart';

/// Deterministic stub adapter proving the AI seam without calling providers.
final class StubAiProviderAdapter implements AiOrchestrationPort {
  const StubAiProviderAdapter();

  @override
  Future<AiCompletionResult> complete(AiCompletionRequest request) async {
    return AiCompletionResult(
      output: {
        'stub': true,
        'purpose': request.purpose,
        'echo': request.input,
      },
      providerLabel: 'eh_stub',
      promptOrTemplateVersion: request.promptOrTemplateVersion,
      warnings: const ['AI stub — no external provider invoked'],
    );
  }
}

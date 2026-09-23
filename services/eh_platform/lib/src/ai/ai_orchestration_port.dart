import 'package:eh_platform/src/ai/ai_completion_request.dart';
import 'package:eh_platform/src/ai/ai_completion_result.dart';

/// Application → AI Orchestration port (PF-ADR-010).
///
/// Domain and application must not import provider SDKs.
/// `services/ai_proxy` remains a separate deployable until Phase 8 absorb.
abstract interface class AiOrchestrationPort {
  Future<AiCompletionResult> complete(AiCompletionRequest request);
}

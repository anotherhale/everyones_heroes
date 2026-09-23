/// AI orchestration request — EH-owned shape, not provider SDK types.
final class AiCompletionRequest {
  const AiCompletionRequest({
    required this.purpose,
    required this.promptOrTemplateVersion,
    required this.input,
    this.correlationId,
  });

  final String purpose;
  final String promptOrTemplateVersion;
  final Map<String, Object?> input;
  final String? correlationId;
}

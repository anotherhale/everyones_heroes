/// AI orchestration result — non-authoritative until domain approval.
final class AiCompletionResult {
  const AiCompletionResult({
    required this.output,
    required this.providerLabel,
    required this.promptOrTemplateVersion,
    this.warnings = const [],
  });

  final Map<String, Object?> output;
  final String providerLabel;
  final String promptOrTemplateVersion;
  final List<String> warnings;
}

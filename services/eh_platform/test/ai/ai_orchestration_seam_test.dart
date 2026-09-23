import 'package:eh_platform/eh_platform.dart';
import 'package:test/test.dart';

void main() {
  group('AI orchestration seam', () {
    test('stub adapter does not require provider credentials', () async {
      const port = StubAiProviderAdapter();
      final result = await port.complete(
        const AiCompletionRequest(
          purpose: 'foundation.ping',
          promptOrTemplateVersion: 'pf3.stub.v1',
          input: {'hello': 'world'},
          correlationId: 'corr',
        ),
      );

      expect(result.providerLabel, 'eh_stub');
      expect(result.promptOrTemplateVersion, 'pf3.stub.v1');
      expect(result.output['stub'], isTrue);
      expect(result.warnings, isNotEmpty);
    });

    test('application depends on port, not provider SDK types', () {
      const AiOrchestrationPort port = StubAiProviderAdapter();
      expect(port, isA<AiOrchestrationPort>());
    });
  });
}

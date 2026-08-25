import 'package:everyonesheroes/core/ids/analyzer_id.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/reflection_emotion.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/features/life_journey/application/services/default_behavioral_evidence_analyzer_registry.dart';
import 'package:everyonesheroes/features/life_journey/domain/domain.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/services/behavioral_analysis/emoji_behavioral_evidence_analyzer.dart';

void main() {
  group('DefaultBehavioralEvidenceAnalyzerRegistry', () {
    const emojiAnalyzer = EmojiBehavioralEvidenceAnalyzer();

    late ReflectionId reflectionId;

    setUp(() {
      reflectionId = ReflectionId.generate();
    });

    test('returns registered analyzer for supported response', () {
      final registry = DefaultBehavioralEvidenceAnalyzerRegistry([
        emojiAnalyzer,
      ]);

      final context = BehavioralEvidenceAnalysisContext(
        reflectionId: reflectionId,
        response: const EmojiResponse(emotion: ReflectionEmotion.excited),
      );

      final analyzers = registry.analyzersFor(context);

      expect(analyzers, contains(same(emojiAnalyzer)));
    });

    test('does not return emoji analyzer for unsupported response', () {
      final registry = DefaultBehavioralEvidenceAnalyzerRegistry([
        emojiAnalyzer,
      ]);

      final context = BehavioralEvidenceAnalysisContext(
        reflectionId: reflectionId,
        response: const JournalResponse(response: 'Today I learned something.'),
      );

      final analyzers = registry.analyzersFor(context);

      expect(analyzers, isEmpty);
    });

    test('exposes registered analyzers', () {
      final registry = DefaultBehavioralEvidenceAnalyzerRegistry([
        emojiAnalyzer,
      ]);

      expect(registry.availableAnalyzers, hasLength(1));
      expect(registry.availableAnalyzers, contains(same(emojiAnalyzer)));
    });

    test('supports multiple registered analyzers', () {
      const fakeAnalyzer = FakeBehavioralEvidenceAnalyzer();

      final registry = DefaultBehavioralEvidenceAnalyzerRegistry([
        emojiAnalyzer,
        fakeAnalyzer,
      ]);

      expect(registry.availableAnalyzers, hasLength(2));
    });
  });
}

final class FakeBehavioralEvidenceAnalyzer
    implements BehavioralEvidenceAnalyzer {
  const FakeBehavioralEvidenceAnalyzer();

  @override
  BehavioralAnalyzerDescriptor get descriptor => BehavioralAnalyzerDescriptor(
    id: AnalyzerId.generate(),
    capabilities: {BehavioralAnalyzerCapability.journal},
  );

  @override
  bool supports(BehavioralEvidenceAnalysisContext context) {
    return context.response is JournalResponse;
  }

  @override
  Future<List<BehavioralEvidence>> analyze(
    BehavioralEvidenceAnalysisContext context,
  ) async {
    return const [];
  }
}

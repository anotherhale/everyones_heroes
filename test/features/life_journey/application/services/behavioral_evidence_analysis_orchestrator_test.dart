import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/reflection_emotion.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/features/life_journey/application/services/behavioral_evidence_analysis_orchestrator.dart';
import 'package:everyonesheroes/features/life_journey/application/services/default_behavioral_evidence_analyzer_registry.dart';
import 'package:everyonesheroes/features/life_journey/domain/domain.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/services/behavioral_analysis/emoji_behavioral_evidence_analyzer.dart';

void main() {
  group('BehavioralEvidenceAnalysisOrchestrator', () {
    const emojiAnalyzer = EmojiBehavioralEvidenceAnalyzer();

    test('selects and executes analyzer registered for response', () async {
      final registry = DefaultBehavioralEvidenceAnalyzerRegistry([
        emojiAnalyzer,
      ]);

      final orchestrator = BehavioralEvidenceAnalysisOrchestrator(
        registry: registry,
      );

      final reflectionId = ReflectionId.generate();

      final reflection = Reflection.create(
        id: reflectionId,
        journeyId: JourneyId.generate(),
      );

      reflection.addResponse(
        const EmojiResponse(emotion: ReflectionEmotion.proud),
      );

      final evidence = await orchestrator.analyze(reflection);

      expect(evidence, hasLength(1));
      expect(evidence.single.type, BehavioralEvidenceType.confidence);
      expect(evidence.single.strength.value, 0.8);
      expect(
        evidence.single.source,
        ReflectionEvidenceSource(reflectionId: reflectionId),
      );
    });

    test('does not invoke analyzer for unsupported response', () async {
      final registry = DefaultBehavioralEvidenceAnalyzerRegistry([
        emojiAnalyzer,
      ]);

      final orchestrator = BehavioralEvidenceAnalysisOrchestrator(
        registry: registry,
      );

      final reflection = Reflection.create(
        id: ReflectionId.generate(),
        journeyId: JourneyId.generate(),
      );

      reflection.addResponse(
        const JournalResponse(response: 'Today was productive.'),
      );

      final evidence = await orchestrator.analyze(reflection);

      expect(evidence, isEmpty);
    });
  });
}

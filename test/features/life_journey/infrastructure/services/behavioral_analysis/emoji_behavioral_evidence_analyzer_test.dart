import 'package:everyonesheroes/features/life_journey/domain/enums/reflection_emotion.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/features/life_journey/domain/domain.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/services/behavioral_analysis/emoji_behavioral_evidence_analyzer.dart';

void main() {
  group('EmojiBehavioralEvidenceAnalyzer', () {
    const analyzer = EmojiBehavioralEvidenceAnalyzer();

    late ReflectionId reflectionId;

    setUp(() {
      reflectionId = ReflectionId.generate();
    });

    BehavioralEvidenceAnalysisContext contextFor(ReflectionEmotion emotion) {
      return BehavioralEvidenceAnalysisContext(
        reflectionId: reflectionId,
        response: EmojiResponse(emotion: emotion),
      );
    }

    test('has emoji capability', () {
      expect(
        analyzer.descriptor.capabilities,
        contains(BehavioralAnalyzerCapability.emoji),
      );
    });

    test('supports emoji responses', () {
      final context = contextFor(ReflectionEmotion.excited);

      expect(analyzer.supports(context), isTrue);
    });

    test('does not support journal responses', () {
      final context = BehavioralEvidenceAnalysisContext(
        reflectionId: reflectionId,
        response: const JournalResponse(
          response: 'I accomplished something difficult today.',
        ),
      );

      expect(analyzer.supports(context), isFalse);
    });

    test('maps excited to confidence', () async {
      final evidence = await analyzer.analyze(
        contextFor(ReflectionEmotion.excited),
      );

      expect(evidence, hasLength(1));
      expect(evidence.single.type, BehavioralEvidenceType.confidence);
      expect(evidence.single.strength.value, 0.8);
      expect(
        evidence.single.source,
        ReflectionEvidenceSource(reflectionId: reflectionId),
      );
    });

    test('maps proud to confidence', () async {
      final evidence = await analyzer.analyze(
        contextFor(ReflectionEmotion.proud),
      );

      expect(evidence.single.type, BehavioralEvidenceType.confidence);
      expect(evidence.single.strength.value, 0.8);
    });

    test('maps grateful to connection', () async {
      final evidence = await analyzer.analyze(
        contextFor(ReflectionEmotion.grateful),
      );

      expect(evidence.single.type, BehavioralEvidenceType.connection);
      expect(evidence.single.strength.value, 0.8);
    });

    test('maps frustrated to resilience', () async {
      final evidence = await analyzer.analyze(
        contextFor(ReflectionEmotion.frustrated),
      );

      expect(evidence.single.type, BehavioralEvidenceType.resilience);
      expect(evidence.single.strength.value, 0.7);
    });

    test('maps anxious to fear', () async {
      final evidence = await analyzer.analyze(
        contextFor(ReflectionEmotion.anxious),
      );

      expect(evidence.single.type, BehavioralEvidenceType.fear);
      expect(evidence.single.strength.value, 0.7);
    });

    test('maps overwhelmed to vulnerability', () async {
      final evidence = await analyzer.analyze(
        contextFor(ReflectionEmotion.overwhelmed),
      );

      expect(evidence.single.type, BehavioralEvidenceType.vulnerability);
      expect(evidence.single.strength.value, 0.7);
    });

    test('maps calm to self-awareness', () async {
      final evidence = await analyzer.analyze(
        contextFor(ReflectionEmotion.calm),
      );

      expect(evidence.single.type, BehavioralEvidenceType.selfAwareness);
      expect(evidence.single.strength.value, 0.8);
    });

    test('maps hopeful to purpose', () async {
      final evidence = await analyzer.analyze(
        contextFor(ReflectionEmotion.hopeful),
      );

      expect(evidence.single.type, BehavioralEvidenceType.purpose);
      expect(evidence.single.strength.value, 0.8);
    });

    test('produces no evidence for neutral emotion', () async {
      final evidence = await analyzer.analyze(
        contextFor(ReflectionEmotion.neutral),
      );

      expect(evidence, isEmpty);
    });

    test(
      'produces no evidence when analyzing an unsupported response',
      () async {
        final context = BehavioralEvidenceAnalysisContext(
          reflectionId: reflectionId,
          response: const JournalResponse(response: 'Today was a good day.'),
        );

        final evidence = await analyzer.analyze(context);

        expect(evidence, isEmpty);
      },
    );

    test('uses the reflection id as the evidence source', () async {
      final evidence = await analyzer.analyze(
        contextFor(ReflectionEmotion.grateful),
      );

      expect(
        evidence.single.source,
        ReflectionEvidenceSource(reflectionId: reflectionId),
      );
    });
  });
}

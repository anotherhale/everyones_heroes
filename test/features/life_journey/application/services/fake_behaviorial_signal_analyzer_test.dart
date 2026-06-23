import '../../../../fakes/life_journey/fake_behavioral_evidence_analyzer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';

import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';

import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/journal_response.dart';

void main() {
  group('FakeBehavioralEvidenceAnalyzer', () {
    const service = FakeBehavioralEvidenceAnalyzer();

    test('returns empty when no responses exist', () async {
      final reflection = Reflection.create(
        id: ReflectionId.generate(),
        journeyId: JourneyId.generate(),
      );

      final evidence = await service.analyze(reflection);

      expect(evidence, isEmpty);
    });

    test('returns evidence when responses exist', () async {
      final reflection = Reflection.create(
        id: ReflectionId.generate(),
        journeyId: JourneyId.generate(),
      );

      reflection.addResponse(const JournalResponse(text: 'Test'));

      final evidence = await service.analyze(reflection);

      expect(evidence, isNotEmpty);
    });
  });
}

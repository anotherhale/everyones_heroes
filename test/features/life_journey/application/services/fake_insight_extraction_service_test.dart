import 'package:everyonesheroes/features/life_journey/infrastructure/services/fake/fake_insight_extraction_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';

import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';

import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/journal_response.dart';

void main() {
  group(
    'FakeInsightExtractionService',
    () {
      const service =
          FakeInsightExtractionService();

      test(
        'returns empty when no responses exist',
        () async {
          final reflection =
              Reflection.create(
            id: ReflectionId.generate(),
            journeyId:
                JourneyId.generate(),
          );

          final insights =
              await service
                  .extractInsights(
            reflection,
          );

          expect(
            insights,
            isEmpty,
          );
        },
      );

      test(
        'returns insight when responses exist',
        () async {
          final reflection =
              Reflection.create(
            id: ReflectionId.generate(),
            journeyId:
                JourneyId.generate(),
          );

          reflection.addResponse(
            const JournalResponse(
              text: 'Test',
            ),
          );

          final insights =
              await service
                  .extractInsights(
            reflection,
          );

          expect(
            insights,
            isNotEmpty,
          );
        },
      );
    },
  );
}
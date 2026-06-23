import 'package:everyonesheroes/features/life_journey/domain/services/insight_extraction_service.dart';

import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/insight.dart';

final class FakeInsightExtractionService implements InsightExtractionService {
  const FakeInsightExtractionService();

  @override
  Future<List<Insight>> extractInsights(Reflection reflection) async {
    if (reflection.responses.isEmpty) {
      return [];
    }

    return [
      Insight(
        statement: 'User demonstrated self-reflection.',
        confidence: 0.90,
      ),
    ];
  }
}

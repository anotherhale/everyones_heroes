import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';
import 'package:everyonesheroes/features/life_journey/domain/services/insight_extraction_service.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/insight.dart';

final class RuleBasedInsightExtractionService
    implements InsightExtractionService {
  @override
  Future<List<Insight>> extractInsights(Reflection reflection) {
    return Future.value([
      Insight(statement: "Insight extracted from reflection", confidence: 0.8),
    ]);
  }
}

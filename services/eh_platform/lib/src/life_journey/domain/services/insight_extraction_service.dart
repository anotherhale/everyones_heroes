import 'package:eh_platform/src/life_journey/domain/aggregates/reflection.dart';
import 'package:eh_platform/src/life_journey/domain/value_objects/insight.dart';

abstract interface class InsightExtractionService {
  Future<List<Insight>> extractInsights(Reflection reflection);
}

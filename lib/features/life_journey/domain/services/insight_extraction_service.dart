import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/insight.dart';

abstract interface class InsightExtractionService {
  Future<List<Insight>> extractInsights(
    Reflection reflection,
  );
}
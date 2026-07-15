import 'package:everyonesheroes/features/life_journey/application/providers/fake/services/fake_insight_extraction_service.dart';
import 'package:everyonesheroes/features/life_journey/domain/services/insight_extraction_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final insightExtractionServiceProvider = Provider<InsightExtractionService>((
  ref,
) {
  return FakeInsightExtractionService();
});

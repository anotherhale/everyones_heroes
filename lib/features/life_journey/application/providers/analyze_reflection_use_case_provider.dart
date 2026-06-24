import 'package:everyonesheroes/core/eventing/event_providers.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/behavioral_evidence_analyzer_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/insight_extraction_service_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/narrative_theme_resolver_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/reflection_repository_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/analyze_reflection_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyzeReflectionUseCaseProvider = Provider<AnalyzeReflectionUseCase>((
  ref,
) {
  return AnalyzeReflectionUseCase(
    reflectionRepository: ref.read(reflectionRepositoryProvider),

    insightExtractionService: ref.read(insightExtractionServiceProvider),

    behavioralEvidenceAnalyzer: ref.read(behavioralEvidenceAnalyzerProvider),

    narrativeThemeResolver: ref.read(narrativeThemeResolverProvider),

    eventBus: ref.read(eventBusProvider),
  );
});

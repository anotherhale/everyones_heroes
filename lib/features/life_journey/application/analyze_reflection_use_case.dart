import 'package:everyonesheroes/core/eventing/event_bus.dart';

import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';

import 'package:everyonesheroes/features/life_journey/infrastructure/services/behavioral_evidencel_analyzer.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/services/insight_extraction_service.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/services/narrative_theme_resolver.dart';

import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';

import 'package:everyonesheroes/features/life_journey/domain/repositories/reflection_repository.dart';

import 'analyze_reflection_request.dart';

final class AnalyzeReflectionUseCase {
  const AnalyzeReflectionUseCase({
    required ReflectionRepository reflectionRepository,
    required InsightExtractionService insightExtractionService,
    required BehavioralEvidenceAnalyzer BehavioralEvidenceAnalyzer,
    required NarrativeThemeResolver narrativeThemeResolver,
    required EventBus eventBus,
  }) : _reflectionRepository = reflectionRepository,
       _insightExtractionService = insightExtractionService,
       _BehavioralEvidenceAnalyzer = BehavioralEvidenceAnalyzer,
       _narrativeThemeResolver = narrativeThemeResolver,
       _eventBus = eventBus;

  final ReflectionRepository _reflectionRepository;

  final InsightExtractionService _insightExtractionService;

  final BehavioralEvidenceAnalyzer _BehavioralEvidenceAnalyzer;

  final NarrativeThemeResolver _narrativeThemeResolver;

  final EventBus _eventBus;

  Future<Result<Reflection>> execute(AnalyzeReflectionRequest request) async {
    try {
      final reflection = await _reflectionRepository.findById(
        request.reflectionId,
      );

      if (reflection == null) {
        return Failure(
          'Reflection not found: '
          '${request.reflectionId.value}',
        );
      }

      final insights = await _insightExtractionService.extractInsights(
        reflection,
      );

      reflection.addInsights(insights);

      final evidence = await _BehavioralEvidenceAnalyzer.analyze(reflection);

      reflection.addbehavioralEvidence(evidence);

      final themes = await _narrativeThemeResolver.resolveThemes(reflection);

      reflection.addNarrativeThemes(themes);

      await _reflectionRepository.save(reflection);

      for (final event in reflection.domainEvents) {
        await _eventBus.publish(event);
      }

      reflection.clearDomainEvents();

      return Success(reflection);
    } catch (e) {
      return Failure(
        'Failed to analyze reflection: '
        '$e',
      );
    }
  }
}

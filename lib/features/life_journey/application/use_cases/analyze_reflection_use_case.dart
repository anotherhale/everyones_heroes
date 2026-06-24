import 'package:everyonesheroes/core/eventing/event_bus.dart';

import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';

import 'package:everyonesheroes/features/life_journey/domain/services/behavioral_evidence_analyzer.dart';
import 'package:everyonesheroes/features/life_journey/domain/services/insight_extraction_service.dart';
import 'package:everyonesheroes/features/life_journey/domain/services/narrative_theme_resolver.dart';

import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';

import 'package:everyonesheroes/features/life_journey/domain/repositories/reflection_repository.dart';

import '../requests/analyze_reflection_request.dart';

final class AnalyzeReflectionUseCase {
  const AnalyzeReflectionUseCase({
    required this._reflectionRepository,
    required this._insightExtractionService,
    required this._behavioralEvidenceAnalyzer,
    required this._narrativeThemeResolver,
    required this._eventBus,
  });

  final ReflectionRepository _reflectionRepository;

  final InsightExtractionService _insightExtractionService;

  final BehavioralEvidenceAnalyzer _behavioralEvidenceAnalyzer;

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

      // Capture events that already existed when analysis started.
      // This prevents ReflectionSubmitted from being republished
      // and recursively invoking this use case.
      final existingEventCount = reflection.domainEvents.length;

      final insights = await _insightExtractionService.extractInsights(
        reflection,
      );

      reflection.addInsights(insights);

      final evidence = await _behavioralEvidenceAnalyzer.analyze(reflection);

      reflection.addBehavioralEvidence(evidence);

      final themes = await _narrativeThemeResolver.resolveThemes(reflection);

      reflection.addNarrativeThemes(themes);

      await _reflectionRepository.save(reflection);

      final newEvents = reflection.domainEvents
          .skip(existingEventCount)
          .toList(growable: false);

      for (final event in newEvents) {
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

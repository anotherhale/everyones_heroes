import 'package:eh_platform/src/eventing/event_bus.dart';
import 'package:eh_platform/src/shared_kernel/failure.dart';
import 'package:eh_platform/src/shared_kernel/result.dart';
import 'package:eh_platform/src/shared_kernel/success.dart';
import 'package:eh_platform/src/life_journey/application/services/behavioral_evidence_analysis_orchestrator.dart';
import 'package:eh_platform/src/life_journey/application/use_cases/use_case.dart';
import 'package:eh_platform/src/life_journey/domain/services/insight_extraction_service.dart';
import 'package:eh_platform/src/life_journey/domain/services/narrative_theme_resolver.dart';
import 'package:eh_platform/src/life_journey/domain/aggregates/reflection.dart';
import 'package:eh_platform/src/life_journey/domain/repositories/reflection_repository.dart';

import '../dto/requests/analyze_reflection_request.dart';

final class AnalyzeReflectionUseCase
    implements UseCase<AnalyzeReflectionRequest, Reflection> {
  const AnalyzeReflectionUseCase({
    required ReflectionRepository reflectionRepository,
    required InsightExtractionService insightExtractionService,
    required BehavioralEvidenceAnalysisOrchestrator
    behavioralEvidenceAnalysisOrchestrator,
    required NarrativeThemeResolver narrativeThemeResolver,
    required EventBus eventBus,
  }) : _reflectionRepository = reflectionRepository,
       _insightExtractionService = insightExtractionService,
       _behavioralEvidenceAnalysisOrchestrator =
           behavioralEvidenceAnalysisOrchestrator,
       _narrativeThemeResolver = narrativeThemeResolver,
       _eventBus = eventBus;

  final ReflectionRepository _reflectionRepository;
  final InsightExtractionService _insightExtractionService;
  final BehavioralEvidenceAnalysisOrchestrator
  _behavioralEvidenceAnalysisOrchestrator;
  final NarrativeThemeResolver _narrativeThemeResolver;
  final EventBus _eventBus;

  @override
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

      final evidence = await _behavioralEvidenceAnalysisOrchestrator.analyze(
        reflection,
      );

      reflection.addBehavioralEvidence(evidence);

      final themes = await _narrativeThemeResolver.resolveThemes(reflection);

      reflection.addNarrativeThemes(themes);

      await _reflectionRepository.save(reflection);

      final events = reflection.pullDomainEvents();

      for (final event in events) {
        await _eventBus.publish(event);
      }

      return Success(reflection);
    } catch (e) {
      return Failure(
        'Failed to analyze reflection: '
        '$e',
      );
    }
  }
}

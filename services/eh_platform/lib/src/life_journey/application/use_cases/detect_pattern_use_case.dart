import 'package:eh_platform/src/shared_kernel/ids/journey_id.dart';
import 'package:eh_platform/src/shared_kernel/failure.dart';
import 'package:eh_platform/src/shared_kernel/result.dart';
import 'package:eh_platform/src/shared_kernel/success.dart';
import 'package:eh_platform/src/life_journey/application/providers/use_cases/detect_pattern_use_case.dart';
import 'package:eh_platform/src/life_journey/domain/domain.dart';
import 'package:eh_platform/src/eventing/event_bus.dart';

final class DefaultDetectPatternUseCase implements DetectPatternUseCase {
  const DefaultDetectPatternUseCase({
    required JourneyRepository journeyRepository,
    required ReflectionRepository reflectionRepository,
    required PatternDetector detector,
    required EventBus eventBus,
  }) : _journeyRepository = journeyRepository,
       _reflectionRepository = reflectionRepository,
       _detector = detector,
       _eventBus = eventBus;

  final JourneyRepository _journeyRepository;
  final ReflectionRepository _reflectionRepository;
  final PatternDetector _detector;
  final EventBus _eventBus;

  @override
  Future<Result<List<BehaviorPattern>>> execute(JourneyId journeyId) async {
    try {
      final journey = await _journeyRepository.findById(journeyId);

      if (journey == null) {
        return Failure('Journey not found: ${journeyId.value}');
      }

      final reflections = await _reflectionRepository.findByJourneyId(
        journeyId,
      );

      final evidence = reflections
          .expand((reflection) => reflection.behavioralEvidence)
          .toList(growable: false);

      final patterns = _detector.detect(evidence: evidence);

      journey.updateBehaviorPatterns(patterns);

      await _journeyRepository.save(journey);

      final events = journey.pullDomainEvents();

      for (final event in events) {
        await _eventBus.publish(event);
      }

      return Success(patterns);
    } catch (e) {
      return Failure('Failed to detect behavior patterns: $e');
    }
  }
}

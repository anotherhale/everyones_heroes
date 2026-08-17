import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/use_cases/detect_pattern_use_case.dart';
import 'package:everyonesheroes/features/life_journey/domain/domain.dart';
import 'package:everyonesheroes/core/eventing/event_bus.dart';

final class DefaultDetectPatternUseCase implements DetectPatternUseCase {
  const DefaultDetectPatternUseCase({
    required this._journeyRepository,
    required this._reflectionRepository,
    required this._detector,
    required this._eventBus,
  });

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

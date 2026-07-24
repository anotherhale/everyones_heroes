import 'package:everyonesheroes/core/eventing/domain_event_reactor.dart';
import 'package:everyonesheroes/features/life_journey/application/ports/detect_behavior_patterns_use_case.dart';

import 'package:everyonesheroes/features/life_journey/domain/events/behavioral_evidence_detected.dart';

final class BehavioralEvidenceDetectedReactor
    implements DomainEventReactor<BehavioralEvidenceDetected> {
  const BehavioralEvidenceDetectedReactor({
    required DetectBehaviorPatternsUseCase detectBehaviorPatterns,
  }) : _detectBehaviorPatterns = detectBehaviorPatterns;

  final DetectBehaviorPatternsUseCase _detectBehaviorPatterns;

  @override
  Type get eventType => BehavioralEvidenceDetected;

  @override
  Future<void> react(BehavioralEvidenceDetected event) async {
    await _detectBehaviorPatterns(journeyId: event.journeyId);
  }
}

import 'package:everyonesheroes/core/eventing/domain_event_reactor.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/use_cases/detect_pattern_use_case.dart';

import 'package:everyonesheroes/features/life_journey/domain/events/behavioral_evidence_detected.dart';

final class BehavioralEvidenceDetectedReactor
    implements DomainEventReactor<BehavioralEvidenceDetected> {
  const BehavioralEvidenceDetectedReactor({required this._detectPattern});

  final DetectPatternUseCase _detectPattern;

  @override
  Type get eventType => BehavioralEvidenceDetected;

  @override
  Future<void> react(BehavioralEvidenceDetected event) async {
    await _detectPattern.execute(event.journeyId);
  }
}

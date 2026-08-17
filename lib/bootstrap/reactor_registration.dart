import 'package:everyonesheroes/core/eventing/event_dispatcher.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/use_cases/detect_pattern_use_case.dart';
import 'package:everyonesheroes/features/life_journey/application/reactors/behavioral_evidence_detected_reactor.dart';
import 'package:everyonesheroes/features/life_journey/application/reactors/reflection/reflection_submitted_reactor.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/analyze_reflection_use_case.dart';
import 'package:everyonesheroes/features/life_journey/domain/domain.dart';

final class ReactorRegistration {
  static void register({
    required EventDispatcher dispatcher,
    required AnalyzeReflectionUseCase analyzeReflectionUseCase,
    required DetectPatternUseCase detectPatternUseCase,
  }) {
    dispatcher.register<ReflectionSubmitted>(
      ReflectionSubmittedReactor(useCase: analyzeReflectionUseCase),
    );

    dispatcher.register<BehavioralEvidenceDetected>(
      BehavioralEvidenceDetectedReactor(detectPattern: detectPatternUseCase),
    );
  }
}

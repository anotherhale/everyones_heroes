import 'package:everyonesheroes/core/eventing/event_dispatcher.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/use_cases/detect_pattern_use_case.dart';
import 'package:everyonesheroes/features/life_journey/application/reactors/behavioral_evidence_detected_reactor.dart';
import 'package:everyonesheroes/features/life_journey/application/reactors/reflection/reflection_submitted_reactor.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/analyze_reflection_use_case.dart';
import 'package:everyonesheroes/features/life_journey/domain/domain.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/platform/eh_platform_config.dart';

final class ReactorRegistration {
  /// Registers Life Journey reactors.
  ///
  /// When EH Platform owns H.2 (`EhPlatformConfig.usePlatformAuthority`),
  /// ReflectionSubmitted / BehavioralEvidenceDetected reactors are **not**
  /// registered — Flutter must not run authoritative analysis or pattern
  /// detection.
  static void register({
    required EventDispatcher dispatcher,
    required AnalyzeReflectionUseCase analyzeReflectionUseCase,
    required DetectPatternUseCase detectPatternUseCase,
  }) {
    if (EhPlatformConfig.usePlatformAuthority) {
      return;
    }

    // TRANSITIONAL: local H.2 reactors for offline/tests without platform.
    // Removal: when EH_PLATFORM_URL is required in all environments (Phase 9).
    dispatcher.register<ReflectionSubmitted>(
      ReflectionSubmittedReactor(useCase: analyzeReflectionUseCase),
    );

    dispatcher.register<BehavioralEvidenceDetected>(
      BehavioralEvidenceDetectedReactor(detectPattern: detectPatternUseCase),
    );
  }
}

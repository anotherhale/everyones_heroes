import 'package:everyonesheroes/core/eventing/event_providers.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/repositories/journey_repository_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/repositories/reflection_repository_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/services/pattern_detector_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/use_cases/detect_pattern_use_case.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/detect_pattern_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final detectPatternUseCaseProvider = Provider<DetectPatternUseCase>((ref) {
  return DefaultDetectPatternUseCase(
    journeyRepository: ref.read(journeyRepositoryProvider),
    reflectionRepository: ref.read(reflectionRepositoryProvider),
    detector: ref.read(patternDetectorProvider),
    eventBus: ref.read(eventBusProvider),
  );
});

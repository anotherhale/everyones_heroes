import 'package:everyonesheroes/core/eventing/event_dispatcher.dart';
import 'package:everyonesheroes/features/life_journey/application/event_handlers/reflection_submitted_handler.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/analyze_reflection_use_case.dart';
import 'package:everyonesheroes/features/life_journey/domain/events/reflection_submitted.dart';

final class EventPipelineRegistration {
  static void register({
    required EventDispatcher dispatcher,
    required AnalyzeReflectionUseCase analyzeReflectionUseCase,
  }) {
    dispatcher.register<ReflectionSubmitted>(
      ReflectionSubmittedHandler(useCase: analyzeReflectionUseCase),
    );
  }
}

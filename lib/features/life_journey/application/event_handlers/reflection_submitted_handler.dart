import 'package:everyonesheroes/core/eventing/event_handler.dart';
import 'package:everyonesheroes/features/life_journey/application/requests/analyze_reflection_request.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/analyze_reflection_use_case.dart';
import 'package:everyonesheroes/features/life_journey/domain/events/reflection_submitted.dart';

final class ReflectionSubmittedHandler
    implements EventHandler<ReflectionSubmitted> {
  ReflectionSubmittedHandler({required this._useCase});

  final AnalyzeReflectionUseCase _useCase;

  @override
  Future<void> handle(ReflectionSubmitted event) async {
    final result = await _useCase.execute(
      AnalyzeReflectionRequest(reflectionId: event.reflectionId),
    );
    result.fold(
      onSuccess: (value) {
        // Handle success case
      },
      onFailure: (error) {
        // Handle failure case
      },
    );
  }
}

import 'package:everyonesheroes/core/eventing/domain_event_reactor.dart';
import 'package:everyonesheroes/features/life_journey/application/dto/requests/analyze_reflection_request.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/analyze_reflection_use_case.dart';
import 'package:everyonesheroes/features/life_journey/domain/events/reflection_submitted.dart';

final class ReflectionSubmittedReactor
    implements DomainEventReactor<ReflectionSubmitted> {
  ReflectionSubmittedReactor({required this._useCase});

  final AnalyzeReflectionUseCase _useCase;

  @override
  Type get eventType => ReflectionSubmitted;

  @override
  Future<void> react(ReflectionSubmitted event) async {
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

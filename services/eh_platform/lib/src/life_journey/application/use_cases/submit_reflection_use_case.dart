import 'package:eh_platform/src/events/event_bus.dart';
import 'package:eh_platform/src/shared_kernel/result.dart';
import 'package:eh_platform/src/life_journey/application/use_cases/use_case.dart';
import 'package:eh_platform/src/life_journey/domain/aggregates/reflection.dart';
import 'package:eh_platform/src/life_journey/domain/repositories/reflection_repository.dart';

import '../dto/requests/submit_reflection_request.dart';

abstract interface class SubmitReflectionUseCase
    implements UseCase<SubmitReflectionRequest, Reflection> {}

final class DefaultSubmitReflectionUseCase implements SubmitReflectionUseCase {
  const DefaultSubmitReflectionUseCase({
    required ReflectionRepository reflectionRepository,
    required EventBus eventBus,
  }) : _reflectionRepository = reflectionRepository,
       _eventBus = eventBus;

  final ReflectionRepository _reflectionRepository;
  final EventBus _eventBus;

  @override
  Future<Result<Reflection>> execute(SubmitReflectionRequest request) async {
    try {
      final reflection = await _reflectionRepository.findById(
        request.reflectionId,
      );

      if (reflection == null) {
        return Failure(code: 'operation_failed', message: 'Reflection not found: ${request.reflectionId.value}');
      }

      reflection.submit();

      await _reflectionRepository.save(reflection);

      final events = reflection.pullDomainEvents();

      for (final event in events) {
        await _eventBus.publish(event);
      }

      return Success(reflection);
    } catch (e) {
      return Failure(code: 'operation_failed', message: 'Failed to submit reflection: $e');
    }
  }
}

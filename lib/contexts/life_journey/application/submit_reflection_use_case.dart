import 'package:everyonesheroes/core/eventing/event_bus.dart';

import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';

import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';

import 'package:everyonesheroes/features/life_journey/domain/repositories/reflection_repository.dart';

import 'submit_reflection_request.dart';

final class SubmitReflectionUseCase {
  const SubmitReflectionUseCase({
    required this._reflectionRepository,
    required this._eventBus,
  });

  final ReflectionRepository
      _reflectionRepository;

  final EventBus _eventBus;

  Future<Result<Reflection>>
      execute(
    SubmitReflectionRequest request,
  ) async {
    try {
      final reflection =
          await _reflectionRepository
              .findById(
        request.reflectionId,
      );

      if (reflection == null) {
        return Failure(
          'Reflection not found: '
          '${request.reflectionId.value}',
        );
      }

      reflection.submit();

      await _reflectionRepository
          .save(
        reflection,
      );

      for (final event
          in reflection.domainEvents) {
        await _eventBus.publish(
          event,
        );
      }

      reflection.clearDomainEvents();

      return Success(
        reflection,
      );
    } catch (e) {
      return Failure(
        'Failed to submit reflection: '
        '$e',
      );
    }
  }
}
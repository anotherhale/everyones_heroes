import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';

import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';

import 'package:everyonesheroes/features/life_journey/domain/repositories/reflection_repository.dart';

import 'create_reflection_request.dart';

final class CreateReflectionUseCase {
  const CreateReflectionUseCase({
    required ReflectionRepository reflectionRepository,
  }) : _reflectionRepository = reflectionRepository;

  final ReflectionRepository _reflectionRepository;

  Future<Result<Reflection>> execute(
    CreateReflectionRequest request,
  ) async {
    try {
      final reflection = Reflection.create(
        id: request.reflectionId,
        journeyId: request.journeyId,
        questId: request.questId,
        missionId: request.missionId,
      );

      await _reflectionRepository.save(
        reflection,
      );

      return Success(reflection);
    } catch (e) {
      return Failure(
        'Failed to create reflection: $e',
      );
    }
  }
}
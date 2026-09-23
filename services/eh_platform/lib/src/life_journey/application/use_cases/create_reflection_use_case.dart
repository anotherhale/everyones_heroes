import 'package:eh_platform/src/shared_kernel/failure.dart';
import 'package:eh_platform/src/shared_kernel/result.dart';
import 'package:eh_platform/src/shared_kernel/success.dart';
import 'package:eh_platform/src/life_journey/application/use_cases/use_case.dart';
import 'package:eh_platform/src/life_journey/domain/aggregates/reflection.dart';
import 'package:eh_platform/src/life_journey/domain/repositories/reflection_repository.dart';

import '../dto/requests/create_reflection_request.dart';

final class CreateReflectionUseCase
    implements UseCase<CreateReflectionRequest, Reflection> {
  const CreateReflectionUseCase({
    required ReflectionRepository reflectionRepository,
  }) : _reflectionRepository = reflectionRepository;

  final ReflectionRepository _reflectionRepository;

  @override
  Future<Result<Reflection>> execute(CreateReflectionRequest request) async {
    try {
      final reflection = Reflection.create(
        id: request.reflectionId,
        journeyId: request.journeyId,
        questId: request.questId,
        missionId: request.missionId,
      );

      await _reflectionRepository.save(reflection);

      return Success(reflection);
    } catch (e) {
      return Failure('Failed to create reflection: $e');
    }
  }
}

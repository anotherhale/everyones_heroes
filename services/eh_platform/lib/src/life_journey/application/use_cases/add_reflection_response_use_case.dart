import 'package:eh_platform/src/shared_kernel/ids/reflection_id.dart';
import 'package:eh_platform/src/shared_kernel/result.dart';
import 'package:eh_platform/src/life_journey/domain/aggregates/reflection.dart';
import 'package:eh_platform/src/life_journey/domain/entities/reflection/reflection_response.dart';
import 'package:eh_platform/src/life_journey/domain/repositories/reflection_repository.dart';

abstract interface class AddReflectionResponseUseCase {
  Future<Result<Reflection>> execute({
    required ReflectionId reflectionId,
    required ReflectionResponse response,
  });
}

final class DefaultAddReflectionResponseUseCase
    implements AddReflectionResponseUseCase {
  const DefaultAddReflectionResponseUseCase({
    required this.reflectionRepository,
  });

  final ReflectionRepository reflectionRepository;

  @override
  Future<Result<Reflection>> execute({
    required ReflectionId reflectionId,
    required ReflectionResponse response,
  }) async {
    try {
      final reflection = await reflectionRepository.findById(reflectionId);

      if (reflection == null) {
        return Failure(code: 'operation_failed', message: 'Reflection not found: ${reflectionId.value}');
      }

      reflection.addResponse(response);
      await reflectionRepository.save(reflection);

      return Success(reflection);
    } catch (e) {
      return Failure(code: 'operation_failed', message: 'Failed to add reflection response: $e');
    }
  }
}

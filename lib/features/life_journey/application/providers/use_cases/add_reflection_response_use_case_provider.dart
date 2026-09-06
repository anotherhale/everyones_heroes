import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../use_cases/add_reflection_response_use_case.dart';
import '../repositories/reflection_repository_provider.dart';

final addReflectionResponseUseCaseProvider =
    Provider<AddReflectionResponseUseCase>((ref) {
      final reflectionRepository = ref.read(reflectionRepositoryProvider);

      return DefaultAddReflectionResponseUseCase(
        reflectionRepository: reflectionRepository,
      );
    });

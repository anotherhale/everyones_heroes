import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/life_journey/application/providers/repositories/reflection_repository_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/create_reflection_use_case.dart';

final createReflectionUseCaseProvider = Provider<CreateReflectionUseCase>((
  ref,
) {
  return CreateReflectionUseCase(
    reflectionRepository: ref.read(reflectionRepositoryProvider),
  );
});

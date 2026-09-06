import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/eventing/event_providers.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/repositories/reflection_repository_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/submit_reflection_use_case.dart';

final submitReflectionUseCaseProvider =
    Provider<SubmitReflectionUseCase>((ref) {
  return DefaultSubmitReflectionUseCase(
    reflectionRepository: ref.read(reflectionRepositoryProvider),
    eventBus: ref.read(eventBusProvider),
  );
});

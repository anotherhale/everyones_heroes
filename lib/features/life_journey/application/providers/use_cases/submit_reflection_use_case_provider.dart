import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/eventing/event_providers.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/repositories/journey_repository_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/repositories/reflection_repository_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/platform_submit_reflection_use_case.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/submit_reflection_use_case.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/platform/eh_platform_client.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/platform/eh_platform_config.dart';

final ehPlatformClientProvider = Provider<EhPlatformClient?>((ref) {
  if (!EhPlatformConfig.usePlatformAuthority) {
    return null;
  }
  return EhPlatformClient.fromConfig();
});

/// H.2 submit — platform-authoritative when [EhPlatformConfig.usePlatformAuthority].
///
/// Local [DefaultSubmitReflectionUseCase] remains only as a transitional path
/// for tests/offline demos without EH Platform (see H.2-Platform-Migration.md).
final submitReflectionUseCaseProvider =
    Provider<SubmitReflectionUseCase>((ref) {
  final client = ref.watch(ehPlatformClientProvider);
  if (client != null) {
    return PlatformSubmitReflectionUseCase(
      client: client,
      journeyRepository: ref.read(journeyRepositoryProvider),
      reflectionRepository: ref.read(reflectionRepositoryProvider),
    );
  }

  return DefaultSubmitReflectionUseCase(
    reflectionRepository: ref.read(reflectionRepositoryProvider),
    eventBus: ref.read(eventBusProvider),
  );
});

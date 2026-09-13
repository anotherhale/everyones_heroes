import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/life_journey/application/providers/repositories/reflection_repository_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/resolve_adaptive_discovery_signals_use_case.dart';

final resolveAdaptiveDiscoverySignalsUseCaseProvider =
    Provider<ResolveAdaptiveDiscoverySignalsUseCase>((ref) {
      return DefaultResolveAdaptiveDiscoverySignalsUseCase(
        reflectionRepository: ref.read(reflectionRepositoryProvider),
      );
    });

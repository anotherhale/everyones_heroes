import 'package:everyonesheroes/core/eventing/event_dispatcher_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/use_cases/analyze_reflection_use_case_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/use_cases/detect_pattern_use_case_provider.dart';
import 'package:everyonesheroes/core/eventing/event_providers.dart';

import 'reactor_registration.dart';

final class ApplicationBootstrap {
  ApplicationBootstrap({required this._container});

  final ProviderContainer _container;

  Future<void> initialize() async {
    // force creation of event infrastructure

    _container.read(eventStoreProvider);

    _container.read(eventDispatcherProvider);

    _container.read(eventBusProvider);

    ReactorRegistration.register(
      dispatcher: _container.read(eventDispatcherProvider),
      analyzeReflectionUseCase: _container.read(
        analyzeReflectionUseCaseProvider,
      ),
      detectPatternUseCase: _container.read(detectPatternUseCaseProvider),
    );
  }
}

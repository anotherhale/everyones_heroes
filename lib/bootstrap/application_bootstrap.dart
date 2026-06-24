import 'package:everyonesheroes/core/eventing/event_dispatcher_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/analyze_reflection_use_case_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/eventing/event_providers.dart';

import 'event_pipeline_registration.dart';

final class ApplicationBootstrap {
  ApplicationBootstrap({required this._container});

  final ProviderContainer _container;

  Future<void> initialize() async {
    // force creation of event infrastructure

    _container.read(eventStoreProvider);

    _container.read(eventDispatcherProvider);

    _container.read(eventBusProvider);

    EventPipelineRegistration.register(
      dispatcher: _container.read(eventDispatcherProvider),
      analyzeReflectionUseCase: _container.read(
        analyzeReflectionUseCaseProvider,
      ),
    );
  }
}

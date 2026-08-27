import 'package:everyonesheroes/core/eventing/event_dispatcher_provider.dart';
import 'package:everyonesheroes/core/eventing/event_providers.dart';
import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';

import 'package:everyonesheroes/features/life_journey/application/reactors/reflection/reflection_submitted_reactor.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/use_cases/analyze_reflection_use_case_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/repositories/reflection_repository_provider.dart';

import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';
import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/emoji_response.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/reflection_emotion.dart';
import 'package:everyonesheroes/features/life_journey/domain/events/reflection_submitted.dart';

import 'package:everyonesheroes/features/life_journey/domain/repositories/reflection_repository.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_reflection_repository.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Reflection Analysis Pipeline', () {
    late ProviderContainer container;

    late ReflectionRepository repository;

    setUp(() {
      repository = InMemoryReflectionRepository();

      container = ProviderContainer(
        overrides: [reflectionRepositoryProvider.overrideWithValue(repository)],
      );

      final dispatcher = container.read(eventDispatcherProvider);

      final useCase = container.read(analyzeReflectionUseCaseProvider);

      dispatcher.register<ReflectionSubmitted>(
        ReflectionSubmittedReactor(useCase: useCase),
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('submitted reflection is analyzed', () async {
      final reflection = Reflection.create(
        id: ReflectionId.generate(),
        journeyId: JourneyId.generate(),
      );
      reflection.addResponse(
        const EmojiResponse(emotion: ReflectionEmotion.proud),
      );

      await repository.save(reflection);

      reflection.submit();

      final bus = container.read(eventBusProvider);

      for (final event in reflection.pullDomainEvents()) {
        await bus.publish(event);
      }

      final updated = await repository.findById(reflection.id);

      expect(updated, isNotNull);

      expect(updated!.insights, isNotEmpty);

      expect(updated.behavioralEvidence, isNotEmpty);

      expect(updated.narrativeThemes, isNotEmpty);
    });
  });
}

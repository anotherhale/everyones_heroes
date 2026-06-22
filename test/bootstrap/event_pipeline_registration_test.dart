import 'package:everyonesheroes/bootstrap/dependency_registration.dart';
import 'package:everyonesheroes/bootstrap/event_pipeline_registration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventPipelineRegistration', () {
    setUp(() {
      DependencyRegistration.register();
    });

    test('register completes successfully', () {
      expect(() => EventPipelineRegistration.register(), returnsNormally);
    });

    test('register may be called multiple times', () {
      EventPipelineRegistration.register();

      expect(() => EventPipelineRegistration.register(), returnsNormally);
    });

    test('register does not affect initialized infrastructure', () {
      final eventBus = DependencyRegistration.eventBus;

      final dispatcher = DependencyRegistration.dispatcher;

      final eventStore = DependencyRegistration.eventStore;

      EventPipelineRegistration.register();

      expect(identical(eventBus, DependencyRegistration.eventBus), isTrue);

      expect(identical(dispatcher, DependencyRegistration.dispatcher), isTrue);

      expect(identical(eventStore, DependencyRegistration.eventStore), isTrue);
    });
  });
}

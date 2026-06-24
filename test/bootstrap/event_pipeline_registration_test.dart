import 'package:everyonesheroes/bootstrap/event_pipeline_registration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventPipelineRegistration', () {
    test('register completes successfully', () {
      expect(() => EventPipelineRegistration.register(), returnsNormally);
    });

    test('register may be called multiple times', () {
      EventPipelineRegistration.register();

      expect(() => EventPipelineRegistration.register(), returnsNormally);
    });
  });
}

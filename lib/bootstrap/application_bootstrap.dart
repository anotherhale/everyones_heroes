import 'package:everyonesheroes/bootstrap/dependency_registration.dart';
import 'package:everyonesheroes/bootstrap/event_pipeline_registration.dart';

final class ApplicationBootstrap {
  Future<void> initialize() async {
    DependencyRegistration.register();

    EventPipelineRegistration.register();
  }
}

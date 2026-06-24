import 'package:everyonesheroes/bootstrap/application_bootstrap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class AppCompositionRoot {
  static Future<void> initialize() async {
    final container = ProviderContainer();

    final bootstrap = ApplicationBootstrap(container: container);

    await bootstrap.initialize();
  }
}

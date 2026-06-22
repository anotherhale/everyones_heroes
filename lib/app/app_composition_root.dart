import 'package:everyonesheroes/bootstrap/application_bootstrap.dart';

final class AppCompositionRoot {
  static Future<void> initialize() async {
    final bootstrap = ApplicationBootstrap();

    await bootstrap.initialize();
  }
}

import 'package:everyonesheroes/app/app_composition_root.dart';

final class DemoRunner {
  Future<void> run() async {
    await AppCompositionRoot.initialize();

  }
}

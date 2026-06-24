import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/bootstrap/application_bootstrap.dart';

void main() {
  test('initialize completes successfully', () async {
    final container = ProviderContainer();

    final bootstrap = ApplicationBootstrap(container: container);
    await bootstrap.initialize();
  });
}

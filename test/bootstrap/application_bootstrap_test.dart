import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/bootstrap/application_bootstrap.dart';

void main() {
  test('initialize completes successfully', () async {
    final bootstrap = ApplicationBootstrap();

    await bootstrap.initialize();
  });
}

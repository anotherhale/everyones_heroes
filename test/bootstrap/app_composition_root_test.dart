import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/app/app_composition_root.dart';

void main() {
  test('composition root initializes', () async {
    await AppCompositionRoot.initialize();
  });
}

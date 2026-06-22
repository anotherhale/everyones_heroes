import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/bootstrap/dependency_registration.dart';

void main() {
  test('register initializes event infrastructure', () {
    DependencyRegistration.register();

    expect(DependencyRegistration.eventStore, isNotNull);

    expect(DependencyRegistration.dispatcher, isNotNull);

    expect(DependencyRegistration.eventBus, isNotNull);
  });
}

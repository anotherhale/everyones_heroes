import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/eventing/event_providers.dart';

void main() {
  test('providers create isolated event graphs', () {
    final container1 = ProviderContainer();

    final container2 = ProviderContainer();

    final bus1 = container1.read(eventBusProvider);

    final bus2 = container2.read(eventBusProvider);

    expect(identical(bus1, bus2), isFalse);

    container1.dispose();
    container2.dispose();
  });
}

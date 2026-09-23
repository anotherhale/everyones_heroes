import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/features/life_journey/infrastructure/platform/eh_platform_config.dart';

void main() {
  test('platform authority is off by default in tests without dart-defines', () {
    // Without EH_PLATFORM_URL / EH_H2_MODE=platform, local transitional path
    // remains so existing Flutter tests stay green.
    expect(EhPlatformConfig.usePlatformAuthority, isFalse);
  });
}

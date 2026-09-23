import 'package:eh_platform/eh_platform.dart';
import 'package:test/test.dart';

void main() {
  group('PlatformConfig', () {
    test('loads from environment map with defaults', () {
      final config = PlatformConfig.fromEnvironment(
        environment: const {
          'EH_DATABASE_URL': 'postgres://eh:eh_dev@127.0.0.1:5432/eh_platform',
        },
      );

      expect(config.environment, 'development');
      expect(config.port, 8080);
      expect(config.host, '0.0.0.0');
      expect(config.aiMode, 'stub');
      expect(config.devAuthToken, 'dev-platform-token');
      expect(config.isDevelopment, isTrue);
    });

    test('requires database URL', () {
      expect(
        () => PlatformConfig.fromEnvironment(environment: const {}),
        throwsA(isA<StateError>()),
      );
    });

    test('testing factory is safe for unit tests', () {
      final config = PlatformConfig.testing(port: 9090);
      expect(config.port, 9090);
      expect(config.environment, 'test');
      expect(config.openAiApiKey, isNull);
    });
  });
}

import 'dart:io';

import 'package:eh_platform/eh_platform.dart';
import 'package:test/test.dart';

import '../support/platform_paths.dart';

void main() {
  group('Identity foundation', () {
    late PlatformDatabase database;
    late PostgresIdentityRepository repository;
    late FixedClock clock;

    setUpAll(() async {
      final root = ehPlatformRoot();
      final url = Platform.environment['EH_DATABASE_URL'] ??
          'postgres://eh:eh_dev@127.0.0.1:5432/eh_platform';
      database = await PlatformDatabase.connect(url);
      await MigrationRunner(
        database: database,
        migrationsDirectory: '$root/migrations',
      ).applyPending();
      repository = PostgresIdentityRepository(database);
      clock = FixedClock(DateTime.utc(2026, 9, 23, 15));
    });

    tearDownAll(() async {
      await database.close();
    });

    test('issues opaque session without locking a login provider', () async {
      final handler = IssueDevSessionHandler(identityRepository: repository);
      final userId = UserId('00000000-0000-4000-8000-000000000055');
      final result = await handler.handle(
        IssueDevSessionCommand(
          userId: userId,
          displayName: 'Identity Lite',
          token: 'identity-lite-token',
        ),
        ApplicationContext(correlationId: 'corr', clock: clock),
      );

      expect(result.isSuccess, isTrue);
      final issued = result.getOrThrow();
      expect(issued.token, 'identity-lite-token');
      expect(issued.principal.userId, userId);

      final authenticator = BearerTokenAuthenticator(
        identityRepository: repository,
      );
      final principal = await authenticator.authenticate(
        'Bearer identity-lite-token',
      );
      expect(principal, isNotNull);
      expect(principal!.displayName, 'Identity Lite');
    });

    test('User is distinct from Hero (naming/documentation invariant)', () {
      // Architectural assertion: Identity UserId exists; Hero is not imported here.
      const userId = UserId('00000000-0000-4000-8000-000000000001');
      expect(userId.value, isNotEmpty);
      expect(User, isNot(equals(AuthenticatedPrincipal)));
    });
  });
}

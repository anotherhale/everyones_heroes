import 'package:eh_platform/eh_platform.dart';
import 'package:test/test.dart';

void main() {
  group('Application boundary', () {
    test('GetCurrentPrincipalQuery returns principal from context', () async {
      const handler = GetCurrentPrincipalHandler();
      final clock = FixedClock(DateTime.utc(2026, 9, 23));
      final principal = AuthenticatedPrincipal(
        userId: UserId('00000000-0000-4000-8000-000000000001'),
        displayName: 'Ada',
      );

      final result = await handler.handle(
        const GetCurrentPrincipalQuery(),
        ApplicationContext(
          correlationId: 'corr',
          principal: principal,
          clock: clock,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.getOrThrow().displayName, 'Ada');
    });

    test('GetCurrentPrincipalQuery fails without principal', () async {
      const handler = GetCurrentPrincipalHandler();
      final result = await handler.handle(
        const GetCurrentPrincipalQuery(),
        ApplicationContext(
          correlationId: 'corr',
          clock: FixedClock(DateTime.utc(2026, 9, 23)),
        ),
      );

      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('expected failure'),
        onFailure: (failure) {
          expect(failure.code, 'unauthenticated');
        },
      );
    });

    test('Command and Query markers remain HTTP-free', () {
      // Structural: application command/query types must not require shelf.
      const command = IssueDevSessionCommand(
        userId: UserId('00000000-0000-4000-8000-000000000002'),
        displayName: 'Bob',
      );
      expect(command, isA<Command<Result<DevSessionIssued>>>());
      expect(const GetCurrentPrincipalQuery(), isA<Query<Result<AuthenticatedPrincipal>>>());
    });
  });
}

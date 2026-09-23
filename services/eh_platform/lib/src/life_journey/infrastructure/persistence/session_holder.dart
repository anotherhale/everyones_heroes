import 'package:postgres/postgres.dart';

/// Request-scoped PostgreSQL session binder for H.2 repositories.
///
/// PF.3 [UnitOfWork.execute] supplies a [TxSession]; repositories read from
/// this holder so domain/application code never imports PostgreSQL types.
final class SessionHolder {
  Session? _session;

  Session? get session => _session;

  void bind(Session session) {
    _session = session;
  }

  void unbind() {
    _session = null;
  }
}

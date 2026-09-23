import 'package:postgres/postgres.dart';

/// Transactional unit of work for EH Platform persistence (PF.3 / H.2).
///
/// All aggregate saves that participate in a command must use the same
/// [UnitOfWork] session. Commit publishes nothing; callers publish domain
/// events after a successful commit (or run reactors inside the transaction
/// when the H.2 chain requires atomic multi-aggregate updates).
abstract interface class UnitOfWork {
  /// Runs [action] inside a database transaction when a connection is bound.
  Future<T> runInTransaction<T>(Future<T> Function() action);

  /// Active SQL session for repositories (null when using in-memory adapters).
  Session? get session;

  bool get isInTransaction;
}

/// No-op unit of work for in-memory tests.
final class InMemoryUnitOfWork implements UnitOfWork {
  bool _inTx = false;

  @override
  Session? get session => null;

  @override
  bool get isInTransaction => _inTx;

  @override
  Future<T> runInTransaction<T>(Future<T> Function() action) async {
    _inTx = true;
    try {
      return await action();
    } finally {
      _inTx = false;
    }
  }
}

/// PostgreSQL-backed unit of work.
final class PostgresUnitOfWork implements UnitOfWork {
  PostgresUnitOfWork(this._connection);

  final Connection _connection;
  TxSession? _tx;

  @override
  Session? get session => _tx ?? _connection;

  @override
  bool get isInTransaction => _tx != null;

  @override
  Future<T> runInTransaction<T>(Future<T> Function() action) async {
    if (_tx != null) {
      // Nested: reuse existing transaction.
      return action();
    }

    return _connection.runTx((tx) async {
      _tx = tx;
      try {
        return await action();
      } finally {
        _tx = null;
      }
    });
  }
}

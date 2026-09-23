import 'package:eh_platform/src/persistence/database.dart';
import 'package:postgres/postgres.dart';

/// Transaction boundary convention for application use cases.
///
/// Single-aggregate commands: one transaction.
/// Cross-aggregate workflows: orchestrated by application use cases
/// (PF.2 §8.3) — avoid distributed transactions.
final class UnitOfWork {
  UnitOfWork(this._database);

  final PlatformDatabase _database;

  Future<T> execute<T>(Future<T> Function(TxSession session) work) {
    return _database.runInTransaction(work);
  }
}

/// Marker interface for aggregate repository ports (domain-facing).
///
/// Implementations live in infrastructure and must not leak into domain models.
abstract interface class Repository {}

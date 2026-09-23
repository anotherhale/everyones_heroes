import 'package:eh_platform/src/life_journey/infrastructure/persistence/session_holder.dart';
import 'package:eh_platform/src/persistence/unit_of_work.dart';

/// Application/infrastructure transaction boundary for Life Journey.
///
/// Adapts PF.3 [UnitOfWork] without introducing a second platform UoW type.
abstract interface class TransactionBoundary {
  Future<T> run<T>(Future<T> Function() work);
}

final class PlatformTransactionBoundary implements TransactionBoundary {
  PlatformTransactionBoundary({
    required UnitOfWork unitOfWork,
    required SessionHolder sessionHolder,
  })  : _unitOfWork = unitOfWork,
        _sessionHolder = sessionHolder;

  final UnitOfWork _unitOfWork;
  final SessionHolder _sessionHolder;

  @override
  Future<T> run<T>(Future<T> Function() work) {
    return _unitOfWork.execute((session) async {
      _sessionHolder.bind(session);
      try {
        return await work();
      } finally {
        _sessionHolder.unbind();
      }
    });
  }
}

/// In-memory / unit-test boundary (no PostgreSQL transaction).
final class InMemoryTransactionBoundary implements TransactionBoundary {
  const InMemoryTransactionBoundary();

  @override
  Future<T> run<T>(Future<T> Function() work) => work();
}

/// Functional result type for application/domain outcomes.
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  TResult fold<TResult>({
    required TResult Function(T value) onSuccess,
    required TResult Function(Failure<T> failure) onFailure,
  }) {
    final self = this;
    return switch (self) {
      Success<T>(:final value) => onSuccess(value),
      Failure<T>() => onFailure(self),
    };
  }

  T getOrThrow() {
    return fold(
      onSuccess: (value) => value,
      onFailure: (failure) => throw StateError(failure.message),
    );
  }
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure({
    required this.code,
    required this.message,
    this.details = const <String, Object?>{},
  });

  final String code;
  final String message;
  final Map<String, Object?> details;
}

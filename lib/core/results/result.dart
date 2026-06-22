abstract base class Result<T> {
  const Result();

  bool get isSuccess;

  bool get isFailure => !isSuccess;

  TResult fold<TResult>({
    required TResult Function(T value) onSuccess,
    required TResult Function(String error) onFailure,
  });

  Result<R> map<R>(R Function(T value) mapper);

  Result<R> flatMap<R>(Result<R> Function(T value) mapper);

  Result<T> onSuccess(void Function(T value) callback);

  Result<T> onFailure(void Function(String error) callback);

  T getOrElse(T fallback);
}

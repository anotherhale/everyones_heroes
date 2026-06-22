import 'package:everyonesheroes/core/results/result.dart';

final class Success<T> extends Result<T> {
  final T value;

  const Success(this.value);

  @override
  bool get isSuccess => true;

  @override
  TResult fold<TResult>({
    required TResult Function(T value) onSuccess,
    required TResult Function(String error) onFailure,
  }) {
    return onSuccess(value);
  }

  @override
  Result<R> map<R>(R Function(T value) mapper) {
    return Success<R>(mapper(value));
  }

  @override
  Result<R> flatMap<R>(Result<R> Function(T value) mapper) {
    return mapper(value);
  }

  @override
  Result<T> onSuccess(void Function(T value) callback) {
    callback(value);
    return this;
  }

  @override
  Result<T> onFailure(void Function(String error) callback) {
    return this;
  }

  @override
  T getOrElse(T fallback) {
    return value;
  }
}

import 'package:everyonesheroes/core/results/result.dart';

final class Failure<T> extends Result<T> {
  final String error;

  const Failure(this.error);

  @override
  bool get isSuccess => false;

  @override
  TResult fold<TResult>({
    required TResult Function(T value) onSuccess,
    required TResult Function(String error) onFailure,
  }) {
    return onFailure(error);
  }

  @override
  Result<R> map<R>(R Function(T value) mapper) {
    return Failure<R>(error);
  }

  @override
  Result<R> flatMap<R>(Result<R> Function(T value) mapper) {
    return Failure<R>(error);
  }

  @override
  Result<T> onSuccess(void Function(T value) callback) {
    return this;
  }

  @override
  Result<T> onFailure(void Function(String error) callback) {
    callback(error);
    return this;
  }

  @override
  T getOrElse(T fallback) {
    return fallback;
  }
}

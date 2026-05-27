import 'package:movie_recommender_web/core/exceptions/app_exception.dart';

sealed class AsyncResult<T> {
  const AsyncResult();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get data => switch (this) {
        Success<T>(:final T data) => data,
        Failure<T>() => null,
      };

  AppException? get error => switch (this) {
        Success<T>() => null,
        Failure<T>(:final AppException exception) => exception,
      };

  R when<R>({
    required R Function(T data) success,
    required R Function(AppException exception) failure,
  }) {
    return switch (this) {
      Success<T>(:final T data) => success(data),
      Failure<T>(:final AppException exception) => failure(exception),
    };
  }

  R maybeWhen<R>({
    R Function(T data)? success,
    R Function(AppException exception)? failure,
    required R Function() orElse,
  }) {
    return switch (this) {
      Success<T>(:final T data) => success != null ? success(data) : orElse(),
      Failure<T>(:final AppException exception) =>
        failure != null ? failure(exception) : orElse(),
    };
  }
}

class Success<T> extends AsyncResult<T> {
  @override
  final T data;

  const Success(this.data);
}

class Failure<T> extends AsyncResult<T> {
  final AppException exception;

  const Failure(this.exception);
}

Future<AsyncResult<T>> runCatching<T>(Future<T> Function() action) async {
  try {
    final T result = await action();
    return Success<T>(result);
  } catch (e, stackTrace) {
    return Failure<T>(AppException.fromException(e, stackTrace));
  }
}

AsyncResult<T> runCatchingSync<T>(T Function() action) {
  try {
    final T result = action();
    return Success<T>(result);
  } catch (e, stackTrace) {
    return Failure<T>(AppException.fromException(e, stackTrace));
  }
}

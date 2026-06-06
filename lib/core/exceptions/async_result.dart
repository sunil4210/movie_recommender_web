import 'package:movie_recommender_web/core/exceptions/app_exception.dart';

/// Result type used by every service call.
///
/// Pattern: a service returns `Future<AsyncResult<T>>`, the notifier (or page)
/// then `result.when(success: ..., failure: ...)`. This keeps error handling
/// explicit at the call site without try/catch ladders.
sealed class AsyncResult<T> {
  const AsyncResult();

  R when<R>({
    required R Function(T data) success,
    required R Function(AppException exception) failure,
  }) {
    return switch (this) {
      Success<T>(:final T data) => success(data),
      Failure<T>(:final AppException exception) => failure(exception),
    };
  }
}

class Success<T> extends AsyncResult<T> {
  const Success(this.data);
  final T data;
}

class Failure<T> extends AsyncResult<T> {
  const Failure(this.exception);
  final AppException exception;
}

Future<AsyncResult<T>> runCatching<T>(Future<T> Function() action) async {
  try {
    return Success<T>(await action());
  } catch (e, stackTrace) {
    return Failure<T>(AppException.fromException(e, stackTrace));
  }
}

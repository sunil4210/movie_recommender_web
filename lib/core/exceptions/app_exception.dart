class AppException implements Exception {
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  const AppException({required this.message, this.code, this.stackTrace});

  factory AppException.fromException(Object e, [StackTrace? stackTrace]) {
    if (e is AppException) return e;
    return AppException(
      message: e.toString().replaceFirst('Exception: ', ''),
      stackTrace: stackTrace,
    );
  }

  factory AppException.fromStatusCode(int statusCode, [String? body]) {
    switch (statusCode) {
      case 400:
        return AppException(message: body ?? 'Bad request. Please check your input.');
      case 401:
        return AppException(message: body ?? 'Invalid email or password.');
      case 403:
        return AppException(message: body ?? 'You do not have permission to perform this action.');
      case 404:
        return AppException(message: body ?? 'The requested resource was not found.');
      case 409:
        return AppException(message: body ?? 'An account already exists with this email.');
      case 422:
        return AppException(message: body ?? 'Invalid input. Please check your data.');
      case 429:
        return const AppException(message: 'Too many requests. Please try again later.');
      case 500:
        return const AppException(message: 'Server error. Please try again later.');
      case 503:
        return const AppException(message: 'Service unavailable. Please try again later.');
      default:
        return const AppException(message: 'Something went wrong. Please try again.');
    }
  }

  @override
  String toString() => message;
}

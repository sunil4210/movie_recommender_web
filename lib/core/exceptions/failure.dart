class Failure implements Exception {
  final String message;

  const Failure(this.message);

  static const String defaultErrorMessage = 'Something went wrong';

  @override
  String toString() => message;
}

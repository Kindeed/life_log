class AppFailure {
  final String code;
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  const AppFailure({
    required this.code,
    required this.message,
    this.cause,
    this.stackTrace,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppFailure &&
            other.code == code &&
            other.message == message &&
            other.cause == cause &&
            other.stackTrace == stackTrace;
  }

  @override
  int get hashCode => Object.hash(code, message, cause, stackTrace);

  @override
  String toString() => 'AppFailure(code: $code, message: $message)';
}

/// Base exception for API and network failures in the app.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// Thrown when OpenTDB returns a specific response code error.
class OpenTdbException extends ApiException {
  final int responseCode;

  const OpenTdbException(this.responseCode, String message)
      : super(message, responseCode);
}

/// Response Code 1: No results for the requested query parameters.
class OpenTdbNoResultsException extends OpenTdbException {
  const OpenTdbNoResultsException()
      : super(
          1,
          'No questions found matching your selected criteria. Try adjusting the category, difficulty, or amount.',
        );
}

/// Response Code 2: Invalid query parameter.
class OpenTdbInvalidParameterException extends OpenTdbException {
  const OpenTdbInvalidParameterException()
      : super(2, 'Invalid parameters sent to the quiz service.');
}

/// Response Code 3: Session token not found.
class OpenTdbTokenNotFoundException extends OpenTdbException {
  const OpenTdbTokenNotFoundException()
      : super(3, 'Quiz session token not found. Please refresh.');
}

/// Response Code 4: Token empty (all questions exhausted).
class OpenTdbTokenEmptyException extends OpenTdbException {
  const OpenTdbTokenEmptyException()
      : super(4, 'All questions for this session have been answered.');
}

/// Response Code 5: Rate limit reached.
class OpenTdbRateLimitException extends OpenTdbException {
  const OpenTdbRateLimitException()
      : super(
          5,
          'Too many requests! OpenTDB allows 1 request per 5 seconds. Please wait a few seconds and try again.',
        );
}

/// Thrown for connection / network issues (timeout, no internet, unreachable host).
class NetworkException extends ApiException {
  const NetworkException(super.message);
}

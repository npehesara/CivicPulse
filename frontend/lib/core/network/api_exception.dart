class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? error;
  final String? path;
  final Map<String, String>? validationErrors;

  ApiException({
    required this.message,
    this.statusCode,
    this.error,
    this.path,
    this.validationErrors,
  });

  factory ApiException.fromResponse(int statusCode, Map<String, dynamic>? data) {
    if (data == null) {
      return ApiException(
        statusCode: statusCode,
        message: _defaultMessageForStatus(statusCode),
      );
    }

    String message = data['message'] as String? ?? _defaultMessageForStatus(statusCode);
    String? error = data['error'] as String?;
    String? path = data['path'] as String?;
    Map<String, String>? validationErrors;

    if (data['validationErrors'] is Map) {
      validationErrors = (data['validationErrors'] as Map).map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    }

    return ApiException(
      statusCode: statusCode,
      message: message,
      error: error,
      path: path,
      validationErrors: validationErrors,
    );
  }

  factory ApiException.networkError([String? details]) {
    return ApiException(
      statusCode: 0,
      message: 'Unable to connect to CivicPulse. Please check your internet connection.',
      error: details,
    );
  }

  static String _defaultMessageForStatus(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request details provided.';
      case 401:
        return 'Invalid email or password.';
      case 403:
        return 'Access denied or account suspended.';
      case 404:
        return 'The requested resource was not found.';
      case 409:
        return 'An account or record with these details already exists.';
      case 500:
        return 'A server error occurred. Please try again later.';
      default:
        return 'An unexpected error occurred ($statusCode).';
    }
  }

  @override
  String toString() => message;
}

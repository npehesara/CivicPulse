/// Exception thrown during OAuth 2.0 / 2.1 authentication workflows.
class OAuthException implements Exception {
  final String message;
  final String? error;
  final String? errorDescription;
  final bool isUserCancelled;

  const OAuthException({
    required this.message,
    this.error,
    this.errorDescription,
    this.isUserCancelled = false,
  });

  factory OAuthException.userCancelled() {
    return const OAuthException(
      message: 'Sign in was cancelled by the user.',
      error: 'user_cancelled',
      isUserCancelled: true,
    );
  }

  factory OAuthException.authorizationFailed([String? details]) {
    return OAuthException(
      message: 'Authorization failed. Please try again.',
      error: 'authorization_failed',
      errorDescription: details,
    );
  }

  factory OAuthException.tokenExchangeFailed([String? details]) {
    return OAuthException(
      message: 'Failed to exchange authorization code for tokens.',
      error: 'token_exchange_failed',
      errorDescription: details,
    );
  }

  factory OAuthException.networkError([String? details]) {
    return OAuthException(
      message: 'Network error occurred during sign in. Please check your connection.',
      error: 'network_error',
      errorDescription: details,
    );
  }

  @override
  String toString() {
    if (errorDescription != null && errorDescription!.isNotEmpty) {
      return 'OAuthException: $message ($errorDescription)';
    }
    return 'OAuthException: $message';
  }
}

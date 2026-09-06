/// Model representing an OAuth 2.0 / 2.1 token session.
///
/// Contains the access token, optional refresh and ID tokens,
/// and expiration metadata. Sensitive credentials should never be logged.
class OAuthSession {
  final String accessToken;
  final String? refreshToken;
  final String? idToken;
  final DateTime? accessTokenExpiration;
  final String? tokenType;
  final List<String>? scopes;

  const OAuthSession({
    required this.accessToken,
    this.refreshToken,
    this.idToken,
    this.accessTokenExpiration,
    this.tokenType = 'Bearer',
    this.scopes,
  });

  /// Checks whether the access token is valid and not within the [safetyWindow] of expiring.
  ///
  /// Default safety window is 60 seconds.
  bool hasValidAccessToken({Duration safetyWindow = const Duration(seconds: 60)}) {
    if (accessToken.isEmpty) {
      return false;
    }
    if (accessTokenExpiration == null) {
      // If no expiration is provided, treat the non-empty token as valid.
      return true;
    }
    final expiryThreshold = accessTokenExpiration!.subtract(safetyWindow);
    return DateTime.now().isBefore(expiryThreshold);
  }

  /// Whether the access token is expired or expiring within 60 seconds.
  bool get isExpired => !hasValidAccessToken();

  /// Whether a valid refresh token exists in this session.
  bool get hasRefreshToken => refreshToken != null && refreshToken!.trim().isNotEmpty;

  /// Creates a copy of this session with optional updated fields.
  OAuthSession copyWith({
    String? accessToken,
    String? refreshToken,
    String? idToken,
    DateTime? accessTokenExpiration,
    String? tokenType,
    List<String>? scopes,
  }) {
    return OAuthSession(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      idToken: idToken ?? this.idToken,
      accessTokenExpiration: accessTokenExpiration ?? this.accessTokenExpiration,
      tokenType: tokenType ?? this.tokenType,
      scopes: scopes ?? this.scopes,
    );
  }

  /// Safe serialization for storage/caching (excluding logging).
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'id_token': idToken,
      'expires_at': accessTokenExpiration?.toIso8601String(),
      'token_type': tokenType,
      'scopes': scopes,
    };
  }

  /// Deserializes an [OAuthSession] from a stored map.
  factory OAuthSession.fromJson(Map<String, dynamic> json) {
    return OAuthSession(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String?,
      idToken: json['id_token'] as String?,
      accessTokenExpiration: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
      tokenType: json['token_type'] as String? ?? 'Bearer',
      scopes: (json['scopes'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    );
  }

  @override
  String toString() {
    final hasRefresh = hasRefreshToken;
    final exp = accessTokenExpiration?.toIso8601String() ?? 'none';
    return 'OAuthSession(tokenType: $tokenType, hasRefreshToken: $hasRefresh, expiresAt: $exp)';
  }
}

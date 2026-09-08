import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/oauth_session.dart';
import '../../features/authentication/data/models/user_model.dart';

/// Secure session and token manager for CivicPulse.
///
/// Stores OAuth credentials exclusively in [FlutterSecureStorage].
/// Non-sensitive user profile metadata is cached in [SharedPreferences].
class SessionManager {
  // OAuth Secure Storage Keys
  static const String _accessTokenKey = 'civicpulse_access_token';
  static const String _refreshTokenKey = 'civicpulse_refresh_token';
  static const String _idTokenKey = 'civicpulse_id_token';
  static const String _tokenExpiryKey = 'civicpulse_access_token_expiry';
  static const String _tokenTypeKey = 'civicpulse_token_type';
  static const String _tokenScopesKey = 'civicpulse_token_scopes';

  // Legacy Token Key (for backward compatibility during migration)
  static const String _legacyTokenKey = 'civicpulse_jwt_token';

  // SharedPreferences Key (non-sensitive profile data only)
  static const String _userKey = 'civicpulse_user_profile';

  final FlutterSecureStorage _secureStorage;
  SharedPreferences? _prefs;

  // In-memory cache for fast, synchronous access
  OAuthSession? _inMemoryOAuthSession;
  String? _inMemoryLegacyToken;
  UserModel? _inMemoryUser;

  SessionManager({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Initializes SharedPreferences and loads in-memory cached state.
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      // Gracefully continue with secure storage or memory
    }
    _inMemoryOAuthSession = await getOAuthSession();
    _inMemoryLegacyToken = await _getLegacyToken();
    _inMemoryUser = await getUser();
  }

  // ==========================================
  // OAuth Session & Token Operations
  // ==========================================

  /// Saves the complete [OAuthSession] securely into [FlutterSecureStorage].
  ///
  /// Sensitive access, refresh, and ID tokens are NEVER saved to [SharedPreferences].
  Future<void> saveOAuthSession(OAuthSession session) async {
    _inMemoryOAuthSession = session;

    try {
      await _secureStorage.write(key: _accessTokenKey, value: session.accessToken);

      if (session.refreshToken != null && session.refreshToken!.isNotEmpty) {
        await _secureStorage.write(key: _refreshTokenKey, value: session.refreshToken);
      } else {
        await _secureStorage.delete(key: _refreshTokenKey);
      }

      if (session.idToken != null && session.idToken!.isNotEmpty) {
        await _secureStorage.write(key: _idTokenKey, value: session.idToken);
      } else {
        await _secureStorage.delete(key: _idTokenKey);
      }

      if (session.accessTokenExpiration != null) {
        await _secureStorage.write(
          key: _tokenExpiryKey,
          value: session.accessTokenExpiration!.toIso8601String(),
        );
      } else {
        await _secureStorage.delete(key: _tokenExpiryKey);
      }

      if (session.tokenType != null) {
        await _secureStorage.write(key: _tokenTypeKey, value: session.tokenType);
      }

      if (session.scopes != null) {
        await _secureStorage.write(
          key: _tokenScopesKey,
          value: jsonEncode(session.scopes),
        );
      }
    } catch (_) {
      // Secure storage write failure
    }
  }

  /// Retrieves the current access token.
  ///
  /// Checks OAuth access token first, then falls back to legacy token if present.
  Future<String?> getAccessToken() async {
    if (_inMemoryOAuthSession != null && _inMemoryOAuthSession!.accessToken.isNotEmpty) {
      return _inMemoryOAuthSession!.accessToken;
    }

    try {
      final token = await _secureStorage.read(key: _accessTokenKey);
      if (token != null && token.isNotEmpty) {
        return token;
      }
    } catch (_) {}

    return await _getLegacyToken();
  }

  /// Retrieves the stored refresh token from secure storage.
  Future<String?> getRefreshToken() async {
    if (_inMemoryOAuthSession?.refreshToken != null &&
        _inMemoryOAuthSession!.refreshToken!.isNotEmpty) {
      return _inMemoryOAuthSession!.refreshToken;
    }

    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        return refreshToken;
      }
    } catch (_) {}

    return null;
  }

  /// Retrieves the stored ID token from secure storage.
  Future<String?> getIdToken() async {
    if (_inMemoryOAuthSession?.idToken != null &&
        _inMemoryOAuthSession!.idToken!.isNotEmpty) {
      return _inMemoryOAuthSession!.idToken;
    }

    try {
      final idToken = await _secureStorage.read(key: _idTokenKey);
      if (idToken != null && idToken.isNotEmpty) {
        return idToken;
      }
    } catch (_) {}

    return null;
  }

  /// Retrieves the expiration timestamp of the current access token.
  Future<DateTime?> getAccessTokenExpiration() async {
    if (_inMemoryOAuthSession?.accessTokenExpiration != null) {
      return _inMemoryOAuthSession!.accessTokenExpiration;
    }

    try {
      final expiryStr = await _secureStorage.read(key: _tokenExpiryKey);
      if (expiryStr != null && expiryStr.isNotEmpty) {
        return DateTime.tryParse(expiryStr);
      }
    } catch (_) {}

    return null;
  }

  /// Checks whether a valid (non-expired) access token exists.
  ///
  /// A safety window (default 60 seconds) is applied to prevent using near-expired tokens.
  Future<bool> hasValidAccessToken({Duration safetyWindow = const Duration(seconds: 60)}) async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    final expiry = await getAccessTokenExpiration();
    if (expiry == null) {
      // Legacy token or token without expiry metadata: consider valid if present
      return true;
    }

    final threshold = expiry.subtract(safetyWindow);
    return DateTime.now().isBefore(threshold);
  }

  /// Checks whether a refresh token is present in secure storage.
  Future<bool> hasRefreshToken() async {
    final refreshToken = await getRefreshToken();
    return refreshToken != null && refreshToken.isNotEmpty;
  }

  /// Reconstructs the stored [OAuthSession] from secure storage.
  Future<OAuthSession?> getOAuthSession() async {
    if (_inMemoryOAuthSession != null) {
      return _inMemoryOAuthSession;
    }

    try {
      final accessToken = await _secureStorage.read(key: _accessTokenKey);
      if (accessToken == null || accessToken.isEmpty) {
        return null;
      }

      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      final idToken = await _secureStorage.read(key: _idTokenKey);
      final expiryStr = await _secureStorage.read(key: _tokenExpiryKey);
      final tokenType = await _secureStorage.read(key: _tokenTypeKey) ?? 'Bearer';
      final scopesStr = await _secureStorage.read(key: _tokenScopesKey);

      List<String>? scopes;
      if (scopesStr != null && scopesStr.isNotEmpty) {
        try {
          scopes = (jsonDecode(scopesStr) as List<dynamic>).map((e) => e.toString()).toList();
        } catch (_) {}
      }

      final session = OAuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        idToken: idToken,
        accessTokenExpiration: expiryStr != null ? DateTime.tryParse(expiryStr) : null,
        tokenType: tokenType,
        scopes: scopes,
      );

      _inMemoryOAuthSession = session;
      return session;
    } catch (_) {
      return null;
    }
  }

  // ==========================================
  // User Profile & Legacy Compatibility
  // ==========================================

  /// Saves user profile metadata to SharedPreferences.
  Future<void> saveUser(UserModel user) async {
    _inMemoryUser = user;
    try {
      final userJson = jsonEncode(user.toJson());
      await _prefs?.setString(_userKey, userJson);
    } catch (_) {}
  }

  /// Retrieves cached user profile from SharedPreferences.
  Future<UserModel?> getUser() async {
    if (_inMemoryUser != null) {
      return _inMemoryUser;
    }

    final userJson = _prefs?.getString(_userKey);
    if (userJson != null && userJson.isNotEmpty) {
      try {
        final Map<String, dynamic> map = jsonDecode(userJson);
        _inMemoryUser = UserModel.fromJson(map);
        return _inMemoryUser;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Legacy helper for backward compatibility with existing ApiClient.
  Future<String?> getToken() async {
    return await getAccessToken();
  }

  /// Legacy helper for saving session from legacy login response.
  Future<void> saveSession({
    required String token,
    required UserModel user,
  }) async {
    _inMemoryLegacyToken = token;
    _inMemoryUser = user;

    try {
      await _secureStorage.write(key: _legacyTokenKey, value: token);
    } catch (_) {
      await _prefs?.setString(_legacyTokenKey, token);
    }

    await saveUser(user);
  }

  /// Private helper for reading legacy token.
  Future<String?> _getLegacyToken() async {
    if (_inMemoryLegacyToken != null && _inMemoryLegacyToken!.isNotEmpty) {
      return _inMemoryLegacyToken;
    }

    try {
      final token = await _secureStorage.read(key: _legacyTokenKey);
      if (token != null && token.isNotEmpty) {
        _inMemoryLegacyToken = token;
        return token;
      }
    } catch (_) {}

    final fallbackToken = _prefs?.getString(_legacyTokenKey);
    _inMemoryLegacyToken = fallbackToken;
    return fallbackToken;
  }

  /// Checks if the user is considered logged in.
  ///
  /// Returns true if any of the following exist:
  /// - A valid (non-expired) OAuth access token
  /// - An OAuth refresh token (session can be silently restored)
  /// - A legacy JWT token (backward compatibility with pre-OAuth login)
  Future<bool> isLoggedIn() async {
    final hasValidToken = await hasValidAccessToken();
    if (hasValidToken) return true;

    final hasRefresh = await hasRefreshToken();
    if (hasRefresh) return true;

    final legacyToken = await _getLegacyToken();
    return legacyToken != null && legacyToken.isNotEmpty;
  }

  /// Clears all local OAuth credentials, legacy tokens, and cached user profile.
  Future<void> clearSession() async {
    if (kDebugMode) {
      debugPrint('[SessionManager] clearSession: clearing local in-memory state and secure storage tokens');
    }
    _inMemoryOAuthSession = null;
    _inMemoryLegacyToken = null;
    _inMemoryUser = null;

    try {
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _idTokenKey);
      await _secureStorage.delete(key: _tokenExpiryKey);
      await _secureStorage.delete(key: _tokenTypeKey);
      await _secureStorage.delete(key: _tokenScopesKey);
      await _secureStorage.delete(key: _legacyTokenKey);
    } catch (_) {}

    try {
      await _prefs?.remove(_legacyTokenKey);
      await _prefs?.remove(_userKey);
    } catch (_) {}
  }
}

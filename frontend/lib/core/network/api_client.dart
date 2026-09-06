import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../auth/oauth_service.dart';
import '../constants/api_constants.dart';
import '../storage/session_manager.dart';
import 'api_exception.dart';

/// Central HTTP API client for CivicPulse.
///
/// Features:
/// - Pre-expiry access token detection (60s safety window) with auto-refresh.
/// - Single-retry HTTP 401 handling with automatic refresh token rotation.
/// - Secure Bearer token injection without exposing tokens to UI callers.
/// - Seamless JSON serialization and unified error mapping.
class ApiClient {
  final http.Client _client;
  final SessionManager sessionManager;
  final OAuthService? oauthService;

  ApiClient({
    http.Client? client,
    required this.sessionManager,
    this.oauthService,
  }) : _client = client ?? http.Client();

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final baseUrl = ApiConstants.baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$baseUrl$normalizedPath';

    if (queryParameters != null && queryParameters.isNotEmpty) {
      final stringParams = queryParameters.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      );
      return Uri.parse(fullUrl).replace(queryParameters: stringParams);
    }

    return Uri.parse(fullUrl);
  }

  Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await sessionManager.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Checks if the access token is expired or within the safety window (60s)
  /// and automatically triggers a refresh if a refresh token is available.
  Future<void> _ensureValidAccessToken() async {
    if (oauthService == null) return;

    final hasValidToken = await sessionManager.hasValidAccessToken(
      safetyWindow: const Duration(seconds: 60),
    );

    if (!hasValidToken && await sessionManager.hasRefreshToken()) {
      try {
        await oauthService!.refreshAccessToken();
      } catch (_) {
        // If pre-expiry refresh encounters an error, let the initial request
        // proceed; any 401 response will be caught and retried/cleared.
      }
    }
  }

  /// Centralized request dispatcher with pre-expiry refresh and single 401 retry.
  Future<dynamic> _sendRequest(
    Future<http.Response> Function(Map<String, String> headers) makeRequest, {
    required bool requiresAuth,
  }) async {
    try {
      if (requiresAuth) {
        await _ensureValidAccessToken();
      }

      var headers = await _getHeaders(requiresAuth: requiresAuth);
      var response = await makeRequest(headers).timeout(ApiConstants.connectTimeout);

      // Handle 401 Unauthorized: attempt single refresh & retry
      if (response.statusCode == 401 && requiresAuth && await sessionManager.hasRefreshToken()) {
        try {
          if (oauthService != null) {
            await oauthService!.refreshAccessToken();
            // Obtain updated Bearer headers with rotated access token
            headers = await _getHeaders(requiresAuth: requiresAuth);
            // Retry the original request exactly once
            response = await makeRequest(headers).timeout(ApiConstants.connectTimeout);
          }
        } catch (_) {
          await sessionManager.clearSession();
          throw ApiException.unauthorized();
        }

        // If retry still returns 401, clear session and throw unauthorized
        if (response.statusCode == 401) {
          await sessionManager.clearSession();
          throw ApiException.unauthorized();
        }
      }

      return _handleResponse(response);
    } on SocketException catch (e) {
      throw ApiException.networkError(e.message);
    } on TimeoutException {
      throw ApiException.networkError('Request connection timed out.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    final uri = _buildUri(path, queryParameters);
    return _sendRequest(
      (headers) => _client.get(uri, headers: headers),
      requiresAuth: requiresAuth,
    );
  }

  Future<dynamic> post(
    String path, {
    dynamic body,
    bool requiresAuth = true,
  }) async {
    final uri = _buildUri(path);
    return _sendRequest(
      (headers) => _client.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
      requiresAuth: requiresAuth,
    );
  }

  Future<dynamic> put(
    String path, {
    dynamic body,
    bool requiresAuth = true,
  }) async {
    final uri = _buildUri(path);
    return _sendRequest(
      (headers) => _client.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
      requiresAuth: requiresAuth,
    );
  }

  Future<dynamic> delete(
    String path, {
    bool requiresAuth = true,
  }) async {
    final uri = _buildUri(path);
    return _sendRequest(
      (headers) => _client.delete(uri, headers: headers),
      requiresAuth: requiresAuth,
    );
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    Map<String, dynamic>? decodedBody;

    if (response.body.isNotEmpty) {
      try {
        final parsed = jsonDecode(response.body);
        if (parsed is Map<String, dynamic>) {
          decodedBody = parsed;
        } else if (parsed is List) {
          return parsed;
        }
      } catch (_) {
        // Body is not JSON
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      return decodedBody ?? {};
    }

    throw ApiException.fromResponse(statusCode, decodedBody);
  }
}

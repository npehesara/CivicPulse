import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../storage/session_manager.dart';
import 'api_exception.dart';

class ApiClient {
  final http.Client _client;
  final SessionManager sessionManager;

  ApiClient({
    http.Client? client,
    required this.sessionManager,
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
      final token = await sessionManager.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(path, queryParameters);
      final headers = await _getHeaders(requiresAuth: requiresAuth);

      final response = await _client
          .get(uri, headers: headers)
          .timeout(ApiConstants.connectTimeout);

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

  Future<dynamic> post(
    String path, {
    dynamic body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(path);
      final headers = await _getHeaders(requiresAuth: requiresAuth);

      final response = await _client
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConstants.connectTimeout);

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

  Future<dynamic> put(
    String path, {
    dynamic body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(path);
      final headers = await _getHeaders(requiresAuth: requiresAuth);

      final response = await _client
          .put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConstants.connectTimeout);

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

  Future<dynamic> delete(
    String path, {
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(path);
      final headers = await _getHeaders(requiresAuth: requiresAuth);

      final response = await _client
          .delete(uri, headers: headers)
          .timeout(ApiConstants.connectTimeout);

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

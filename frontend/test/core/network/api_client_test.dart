import 'dart:convert';
import 'package:civicpulse_frontend/core/auth/oauth_service.dart';
import 'package:civicpulse_frontend/core/auth/oauth_session.dart';
import 'package:civicpulse_frontend/core/network/api_client.dart';
import 'package:civicpulse_frontend/core/network/api_exception.dart';
import 'package:civicpulse_frontend/core/storage/session_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MockSessionManager extends Fake implements SessionManager {
  String? accessToken = 'valid_token_123';
  String? refreshToken = 'valid_refresh_token';
  DateTime? tokenExpiry = DateTime.now().add(const Duration(minutes: 15));
  bool sessionCleared = false;

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<DateTime?> getAccessTokenExpiration() async => tokenExpiry;

  @override
  Future<bool> hasValidAccessToken({Duration safetyWindow = const Duration(seconds: 60)}) async {
    if (accessToken == null || accessToken!.isEmpty) return false;
    if (tokenExpiry == null) return true;
    return DateTime.now().isBefore(tokenExpiry!.subtract(safetyWindow));
  }

  @override
  Future<bool> hasRefreshToken() async => refreshToken != null && refreshToken!.isNotEmpty;

  @override
  Future<void> saveOAuthSession(OAuthSession session) async {
    accessToken = session.accessToken;
    refreshToken = session.refreshToken;
    tokenExpiry = session.accessTokenExpiration;
  }

  @override
  Future<void> clearSession() async {
    accessToken = null;
    refreshToken = null;
    tokenExpiry = null;
    sessionCleared = true;
  }
}

class MockOAuthService extends Fake implements OAuthService {
  @override
  final MockSessionManager sessionManager;
  int refreshCount = 0;
  bool shouldFailRefresh = false;

  MockOAuthService({required this.sessionManager});

  @override
  Future<OAuthSession> refreshAccessToken() async {
    refreshCount++;
    if (shouldFailRefresh) {
      throw Exception('Refresh token expired');
    }
    final newSession = OAuthSession(
      accessToken: 'refreshed_access_token_999',
      refreshToken: 'rotated_refresh_token_888',
      accessTokenExpiration: DateTime.now().add(const Duration(minutes: 15)),
    );
    await sessionManager.saveOAuthSession(newSession);
    return newSession;
  }
}

void main() {
  late MockSessionManager sessionManager;
  late MockOAuthService oauthService;

  setUp(() {
    sessionManager = MockSessionManager();
    oauthService = MockOAuthService(sessionManager: sessionManager);
  });

  group('ApiClient Auto-Refresh & 401 Retry Tests', () {
    test('valid access token should attach Bearer token and NOT trigger refresh', () async {
      int requestCount = 0;
      final mockHttpClient = MockClient((request) async {
        requestCount++;
        expect(request.headers['Authorization'], 'Bearer valid_token_123');
        return http.Response(jsonEncode({'success': true}), 200);
      });

      final apiClient = ApiClient(
        client: mockHttpClient,
        sessionManager: sessionManager,
        oauthService: oauthService,
      );

      final response = await apiClient.get('/api/test');
      expect(response['success'], isTrue);
      expect(requestCount, 1);
      expect(oauthService.refreshCount, 0);
    });

    test('pre-expiry detection: expired token should refresh before making request', () async {
      // Set expired token
      sessionManager.tokenExpiry = DateTime.now().subtract(const Duration(minutes: 5));

      int requestCount = 0;
      final mockHttpClient = MockClient((request) async {
        requestCount++;
        expect(request.headers['Authorization'], 'Bearer refreshed_access_token_999');
        return http.Response(jsonEncode({'data': 'ok'}), 200);
      });

      final apiClient = ApiClient(
        client: mockHttpClient,
        sessionManager: sessionManager,
        oauthService: oauthService,
      );

      final response = await apiClient.get('/api/test');
      expect(response['data'], 'ok');
      expect(oauthService.refreshCount, 1);
      expect(requestCount, 1);
    });

    test('401 Unauthorized should trigger token refresh and retry request exactly once', () async {
      int requestCount = 0;
      final mockHttpClient = MockClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          // First attempt returns 401 with old token
          expect(request.headers['Authorization'], 'Bearer valid_token_123');
          return http.Response(jsonEncode({'error': 'Unauthorized'}), 401);
        } else {
          // Second attempt (retry) should use refreshed token and succeed
          expect(request.headers['Authorization'], 'Bearer refreshed_access_token_999');
          return http.Response(jsonEncode({'recovered': true}), 200);
        }
      });

      final apiClient = ApiClient(
        client: mockHttpClient,
        sessionManager: sessionManager,
        oauthService: oauthService,
      );

      final response = await apiClient.get('/api/test');
      expect(response['recovered'], isTrue);
      expect(requestCount, 2); // Exactly 1 initial + 1 retry
      expect(oauthService.refreshCount, 1);
    });

    test('401 retry failure (retry returns 401 again) should clear session and stop (no 3rd request)', () async {
      int requestCount = 0;
      final mockHttpClient = MockClient((request) async {
        requestCount++;
        // Both initial request and retry return 401
        return http.Response(jsonEncode({'error': 'Unauthorized'}), 401);
      });

      final apiClient = ApiClient(
        client: mockHttpClient,
        sessionManager: sessionManager,
        oauthService: oauthService,
      );

      expect(
        () => apiClient.get('/api/test'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );

      // Give async pipeline a moment
      await pumpEventQueue();

      expect(requestCount, 2); // 1 initial + 1 retry = 2 total
      expect(sessionManager.sessionCleared, isTrue);
    });

    test('401 with failing refresh should clear session and throw ApiException', () async {
      oauthService.shouldFailRefresh = true;

      int requestCount = 0;
      final mockHttpClient = MockClient((request) async {
        requestCount++;
        return http.Response(jsonEncode({'error': 'Unauthorized'}), 401);
      });

      final apiClient = ApiClient(
        client: mockHttpClient,
        sessionManager: sessionManager,
        oauthService: oauthService,
      );

      expect(
        () => apiClient.get('/api/test'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );

      await pumpEventQueue();

      expect(requestCount, 1); // Only initial request made before refresh failed
      expect(sessionManager.sessionCleared, isTrue);
    });
  });
}

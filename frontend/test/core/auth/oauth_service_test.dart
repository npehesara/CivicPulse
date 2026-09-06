import 'package:civicpulse_frontend/core/auth/oauth_exception.dart';
import 'package:civicpulse_frontend/core/auth/oauth_service.dart';
import 'package:civicpulse_frontend/core/auth/oauth_session.dart';
import 'package:civicpulse_frontend/core/storage/session_manager.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeFlutterAppAuth extends Fake implements FlutterAppAuth {
  bool shouldCancel = false;
  bool shouldThrow = false;
  String? errorToThrow;
  int tokenCallCount = 0;

  @override
  Future<AuthorizationTokenResponse?> authorizeAndExchangeCode(
    AuthorizationTokenRequest request,
  ) async {
    if (shouldCancel) {
      return null;
    }
    if (shouldThrow) {
      throw Exception(errorToThrow ?? 'Network connection failed');
    }
    return AuthorizationTokenResponse(
      'mock_access_token_123',
      'mock_refresh_token_456',
      DateTime.now().add(const Duration(minutes: 15)),
      'mock_id_token_789',
      'Bearer',
      request.scopes,
      null,
      null,
    );
  }

  @override
  Future<TokenResponse?> token(TokenRequest request) async {
    tokenCallCount++;
    if (shouldThrow) {
      throw Exception(errorToThrow ?? 'Invalid refresh token grant');
    }
    return TokenResponse(
      'rotated_access_token_999',
      'rotated_refresh_token_888',
      DateTime.now().add(const Duration(minutes: 15)),
      'rotated_id_token_777',
      'Bearer',
      request.scopes,
      null,
    );
  }
}

class FakeSessionManagerForAuth extends Fake implements SessionManager {
  OAuthSession? storedSession;
  String? storedRefreshToken = 'initial_refresh_token';
  String? storedIdToken = 'initial_id_token';
  bool cleared = false;

  @override
  Future<String?> getRefreshToken() async => storedRefreshToken;

  @override
  Future<String?> getIdToken() async => storedIdToken;

  @override
  Future<void> saveOAuthSession(OAuthSession session) async {
    storedSession = session;
    storedRefreshToken = session.refreshToken;
    storedIdToken = session.idToken;
  }

  @override
  Future<void> clearSession() async {
    storedSession = null;
    storedRefreshToken = null;
    storedIdToken = null;
    cleared = true;
  }
}

void main() {
  late FakeFlutterAppAuth fakeAppAuth;
  late FakeSessionManagerForAuth fakeSessionManager;
  late OAuthService oauthService;

  setUp(() {
    fakeAppAuth = FakeFlutterAppAuth();
    fakeSessionManager = FakeSessionManagerForAuth();
    oauthService = OAuthService(
      appAuth: fakeAppAuth,
      sessionManager: fakeSessionManager,
    );
  });

  group('OAuthService Tests', () {
    test('successful authorize should return OAuthSession and save to SessionManager', () async {
      final session = await oauthService.authorize();

      expect(session.accessToken, 'mock_access_token_123');
      expect(session.refreshToken, 'mock_refresh_token_456');
      expect(session.idToken, 'mock_id_token_789');
      expect(session.tokenType, 'Bearer');
      expect(fakeSessionManager.storedSession, isNotNull);
      expect(fakeSessionManager.storedSession!.accessToken, 'mock_access_token_123');
    });

    test('user cancellation should throw OAuthException.userCancelled', () async {
      fakeAppAuth.shouldCancel = true;

      expect(
        oauthService.authorize(),
        throwsA(
          isA<OAuthException>().having(
            (e) => e.isUserCancelled,
            'isUserCancelled',
            isTrue,
          ),
        ),
      );
      await pumpEventQueue();
      expect(fakeSessionManager.storedSession, isNull);
    });

    test('failure should throw OAuthException and not store session', () async {
      fakeAppAuth.shouldThrow = true;
      fakeAppAuth.errorToThrow = 'Connection refused';

      expect(
        oauthService.authorize(),
        throwsA(isA<OAuthException>()),
      );
      await pumpEventQueue();
      expect(fakeSessionManager.storedSession, isNull);
    });

    test('successful refreshAccessToken should rotate tokens and save to SessionManager', () async {
      final session = await oauthService.refreshAccessToken();

      expect(session.accessToken, 'rotated_access_token_999');
      expect(session.refreshToken, 'rotated_refresh_token_888');
      expect(session.idToken, 'rotated_id_token_777');
      expect(fakeSessionManager.storedSession?.accessToken, 'rotated_access_token_999');
      expect(fakeSessionManager.storedSession?.refreshToken, 'rotated_refresh_token_888');
      expect(fakeAppAuth.tokenCallCount, 1);
    });

    test('concurrent refreshAccessToken calls should trigger only one network request (single-flight)', () async {
      final futures = await Future.wait([
        oauthService.refreshAccessToken(),
        oauthService.refreshAccessToken(),
        oauthService.refreshAccessToken(),
      ]);

      expect(futures.length, 3);
      expect(futures[0].accessToken, 'rotated_access_token_999');
      expect(futures[1].accessToken, 'rotated_access_token_999');
      expect(futures[2].accessToken, 'rotated_access_token_999');
      expect(fakeAppAuth.tokenCallCount, 1); // Only 1 request reached token endpoint
    });

    test('refreshAccessToken with no stored refresh token should clear session and throw', () async {
      fakeSessionManager.storedRefreshToken = null;

      expect(
        oauthService.refreshAccessToken(),
        throwsA(isA<OAuthException>()),
      );
      await pumpEventQueue();
      expect(fakeSessionManager.cleared, isTrue);
    });

    test('refreshAccessToken failure should clear session and throw OAuthException', () async {
      fakeAppAuth.shouldThrow = true;
      fakeAppAuth.errorToThrow = 'invalid_grant';

      expect(
        oauthService.refreshAccessToken(),
        throwsA(isA<OAuthException>()),
      );
      await pumpEventQueue();
      expect(fakeSessionManager.cleared, isTrue);
    });

    test('logout should clear session in SessionManager', () async {
      await oauthService.logout();
      expect(fakeSessionManager.cleared, isTrue);
    });
  });
}
